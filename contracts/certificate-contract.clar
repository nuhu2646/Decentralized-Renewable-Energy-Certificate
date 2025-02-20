;; Certificate Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INSUFFICIENT_BALANCE (err u402))

;; Fungible Token Definition
(define-fungible-token renewable-energy-certificate)

;; Data Maps
(define-map certificates
  { certificate-id: uint }
  {
    owner: principal,
    amount: uint,
    is-retired: bool
  }
)

(define-data-var certificate-nonce uint u0)

;; Functions
(define-public (issue-certificate (producer principal) (amount uint))
  (let
    ((new-certificate-id (+ (var-get certificate-nonce) u1)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (try! (ft-mint? renewable-energy-certificate amount producer))
    (map-set certificates
      { certificate-id: new-certificate-id }
      {
        owner: producer,
        amount: amount,
        is-retired: false
      }
    )
    (var-set certificate-nonce new-certificate-id)
    (ok new-certificate-id)
  )
)

(define-public (transfer (recipient principal) (amount uint))
  (ft-transfer? renewable-energy-certificate amount tx-sender recipient)
)

(define-read-only (get-balance (account principal))
  (ft-get-balance renewable-energy-certificate account)
)

(define-read-only (get-certificate (certificate-id uint))
  (map-get? certificates { certificate-id: certificate-id })
)

