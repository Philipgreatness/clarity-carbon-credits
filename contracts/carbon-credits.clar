;; Carbon Credits Trading System
(define-fungible-token carbon-credit)

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-credits (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-price (err u104))
(define-constant err-invalid-validation (err u105))

;; Data Variables
(define-data-var credit-price uint u1000) ;; price in microstacks
(define-data-var total-credits-issued uint u0)
(define-data-var total-credits-retired uint u0)
(define-data-var min-validation-threshold uint u3) ;; minimum required validations

;; Data Maps
(define-map verified-issuers principal bool)
(define-map verified-validators principal bool)
(define-map credit-metadata
    principal
    {
        issued: uint,
        retired: uint,
        project-type: (string-ascii 50),
        validations: uint,
        price: uint
    }
)
(define-map validation-status
    {issuer: principal, validator: principal}
    bool
)

;; Authorization checks
(define-private (is-issuer (issuer principal))
    (default-to false (map-get? verified-issuers issuer))
)

(define-private (is-validator (validator principal))
    (default-to false (map-get? verified-validators validator))
)

;; Issue new carbon credits
(define-public (issue-credits (amount uint) (project-type (string-ascii 50)) (initial-price uint))
    (let (
        (issuer-data (default-to {issued: u0, retired: u0, project-type: "", validations: u0, price: u0} 
                    (map-get? credit-metadata tx-sender)))
    )
    (asserts! (>= initial-price u0) err-invalid-price)
    (if (is-issuer tx-sender)
        (begin
            (map-set credit-metadata tx-sender 
                (merge issuer-data {
                    issued: (+ amount (get issued issuer-data)),
                    project-type: project-type,
                    validations: u0,
                    price: initial-price
                })
            )
            (ok true)
        )
        err-unauthorized
    ))
)

;; Validate credits
(define-public (validate-credits (issuer principal))
    (let (
        (issuer-data (default-to {issued: u0, retired: u0, project-type: "", validations: u0, price: u0}
                    (map-get? credit-metadata issuer)))
    )
    (asserts! (is-validator tx-sender) err-unauthorized)
    (asserts! (not (default-to false (map-get? validation-status {issuer: issuer, validator: tx-sender}))) err-invalid-validation)
    (begin
        (map-set validation-status {issuer: issuer, validator: tx-sender} true)
        (map-set credit-metadata issuer
            (merge issuer-data {
                validations: (+ (get validations issuer-data) u1)
            })
        )
        (if (>= (+ (get validations issuer-data) u1) (var-get min-validation-threshold))
            (try! (ft-mint? carbon-credit (get issued issuer-data) issuer))
            (ok true)
        )
    ))
)

;; Set credit price
(define-public (set-credit-price (new-price uint))
    (let (
        (issuer-data (default-to {issued: u0, retired: u0, project-type: "", validations: u0, price: u0}
                    (map-get? credit-metadata tx-sender)))
    )
    (asserts! (is-issuer tx-sender) err-unauthorized)
    (asserts! (>= new-price u0) err-invalid-price)
    (begin
        (map-set credit-metadata tx-sender
            (merge issuer-data {
                price: new-price
            })
        )
        (ok true)
    ))
)

;; Transfer credits
(define-public (transfer-credits (amount uint) (sender principal) (recipient principal))
    (begin
        (asserts! (>= amount u0) err-invalid-amount)
        (try! (ft-transfer? carbon-credit amount sender recipient))
        (ok true)
    )
)

;; Retire credits
(define-public (retire-credits (amount uint))
    (let (
        (balance (ft-get-balance carbon-credit tx-sender))
        (metadata (default-to {issued: u0, retired: u0, project-type: "", validations: u0, price: u0}
                (map-get? credit-metadata tx-sender)))
    )
    (if (>= balance amount)
        (begin
            (try! (ft-burn? carbon-credit amount tx-sender))
            (var-set total-credits-retired (+ (var-get total-credits-retired) amount))
            (map-set credit-metadata tx-sender 
                (merge metadata {
                    retired: (+ amount (get retired metadata))
                })
            )
            (ok true)
        )
        err-insufficient-credits
    ))
)

;; Admin functions
(define-public (add-issuer (issuer principal))
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set verified-issuers issuer true)
            (ok true)
        )
        err-owner-only
    )
)

(define-public (remove-issuer (issuer principal))
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-delete verified-issuers issuer)
            (ok true)
        )
        err-owner-only
    )
)

(define-public (add-validator (validator principal))
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set verified-validators validator true)
            (ok true)
        )
        err-owner-only
    )
)

(define-public (remove-validator (validator principal))
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-delete verified-validators validator)
            (ok true)
        )
        err-owner-only
    )
)

;; Read only functions
(define-read-only (get-credit-balance (account principal))
    (ok (ft-get-balance carbon-credit account))
)

(define-read-only (get-issuer-data (issuer principal))
    (ok (map-get? credit-metadata issuer))
)

(define-read-only (get-total-credits-issued)
    (ok (var-get total-credits-issued))
)

(define-read-only (get-total-credits-retired)
    (ok (var-get total-credits-retired))
)

(define-read-only (get-credit-price (issuer principal))
    (ok (get price (default-to {issued: u0, retired: u0, project-type: "", validations: u0, price: u0}
            (map-get? credit-metadata issuer))))
)

(define-read-only (get-validation-status (issuer principal) (validator principal))
    (ok (default-to false (map-get? validation-status {issuer: issuer, validator: validator})))
)
