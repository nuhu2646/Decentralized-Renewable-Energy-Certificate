;; Trading Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_AMOUNT (err u400))

;; Data Maps
(define-map listings
  { listing-id: uint }
  {
    seller: principal,
    amount: uint,
    price-per-unit: uint,
    is-active: bool
  }
)

(define-data-var listing-nonce uint u0)

;; Functions
(define-public (create-listing (amount uint) (price-per-unit uint))
  (let
    ((new-listing-id (+ (var-get listing-nonce) u1)))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (map-set listings
      { listing-id: new-listing-id }
      {
        seller: tx-sender,
        amount: amount,
        price-per-unit: price-per-unit,
        is-active: true
      }
    )
    (var-set listing-nonce new-listing-id)
    (ok new-listing-id)
  )
)

(define-public (cancel-listing (listing-id uint))
  (let
    ((listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq (get seller listing) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (get is-active listing) ERR_NOT_FOUND)
    (ok (map-set listings
      { listing-id: listing-id }
      (merge listing { is-active: false })
    ))
  )
)

(define-public (buy-rec (listing-id uint) (amount uint))
  (let
    ((listing (unwrap! (map-get? listings { listing-id: listing-id }) ERR_NOT_FOUND))
     (total-cost (* amount (get price-per-unit listing))))
    (asserts! (get is-active listing) ERR_NOT_FOUND)
    (asserts! (<= amount (get amount listing)) ERR_INVALID_AMOUNT)
    (try! (stx-transfer? total-cost tx-sender (get seller listing)))
    (ok (map-set listings
      { listing-id: listing-id }
      (merge listing
        {
          amount: (- (get amount listing) amount),
          is-active: (> (- (get amount listing) amount) u0)
        }
      )
    ))
  )
)

(define-read-only (get-listing (listing-id uint))
  (map-get? listings { listing-id: listing-id })
)

