;; Carbon Credits Trading System
(define-fungible-token carbon-credit)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-credits (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-unauthorized (err u103))

;; Data Variables
(define-data-var credit-price uint u1000) ;; price in microstacks
(define-data-var total-credits-issued uint u0)
(define-data-var total-credits-retired uint u0)

;; Data Maps
(define-map verified-issuers principal bool)
(define-map credit-metadata
    principal
    {
        issued: uint,
        retired: uint,
        project-type: (string-ascii 50)
    }
)

;; Authorization check
(define-private (is-issuer (issuer principal))
    (default-to false (map-get? verified-issuers issuer))
)

;; Issue new carbon credits
(define-public (issue-credits (amount uint) (project-type (string-ascii 50)))
    (let (
        (issuer-data (default-to {issued: u0, retired: u0, project-type: ""} 
                    (map-get? credit-metadata tx-sender)))
    )
    (if (is-issuer tx-sender)
        (begin
            (try! (ft-mint? carbon-credit amount tx-sender))
            (var-set total-credits-issued (+ (var-get total-credits-issued) amount))
            (map-set credit-metadata tx-sender 
                (merge issuer-data {
                    issued: (+ amount (get issued issuer-data)),
                    project-type: project-type
                })
            )
            (ok true)
        )
        err-unauthorized
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
        (metadata (default-to {issued: u0, retired: u0, project-type: ""} 
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
