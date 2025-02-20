import { describe, it, expect, beforeEach } from "vitest"

describe("Trading Contract", () => {
  let mockStorage: Map<string, any>
  let listingNonce: number
  
  beforeEach(() => {
    mockStorage = new Map()
    listingNonce = 0
  })
  
  const mockContractCall = (method: string, args: any[], sender: string) => {
    switch (method) {
      case "create-listing":
        const [amount, pricePerUnit] = args
        if (amount <= 0) {
          return { success: false, error: "Invalid amount" }
        }
        listingNonce++
        mockStorage.set(`listing-${listingNonce}`, {
          seller: sender,
          amount,
          "price-per-unit": pricePerUnit,
          "is-active": true,
        })
        return { success: true, value: listingNonce }
      case "cancel-listing":
        const [listingId] = args
        const listing = mockStorage.get(`listing-${listingId}`)
        if (!listing || listing.seller !== sender || !listing["is-active"]) {
          return { success: false, error: "Not authorized or listing not found" }
        }
        listing["is-active"] = false
        mockStorage.set(`listing-${listingId}`, listing)
        return { success: true }
      case "buy-rec":
        const [buyListingId, buyAmount] = args
        const buyListing = mockStorage.get(`listing-${buyListingId}`)
        if (!buyListing || !buyListing["is-active"] || buyAmount > buyListing.amount) {
          return { success: false, error: "Invalid listing or insufficient amount" }
        }
        buyListing.amount -= buyAmount
        buyListing["is-active"] = buyListing.amount > 0
        mockStorage.set(`listing-${buyListingId}`, buyListing)
        return { success: true }
      case "get-listing":
        return { success: true, value: mockStorage.get(`listing-${args[0]}`) }
      default:
        return { success: false, error: "Method not found" }
    }
  }
  
  it("should create a listing", () => {
    const result = mockContractCall("create-listing", [1000, 10], "seller1")
    expect(result.success).toBe(true)
    expect(result.value).toBe(1)
  })
  
  it("should not create a listing with invalid amount", () => {
    const result = mockContractCall("create-listing", [0, 10], "seller1")
    expect(result.success).toBe(false)
  })
  
  it("should cancel a listing", () => {
    mockContractCall("create-listing", [1000, 10], "seller1")
    const result = mockContractCall("cancel-listing", [1], "seller1")
    expect(result.success).toBe(true)
  })
  
  it("should not allow unauthorized cancellation", () => {
    mockContractCall("create-listing", [1000, 10], "seller1")
    const result = mockContractCall("cancel-listing", [1], "seller2")
    expect(result.success).toBe(false)
  })
  
  it("should buy RECs", () => {
    mockContractCall("create-listing", [1000, 10], "seller1")
    const result = mockContractCall("buy-rec", [1, 500], "buyer1")
    expect(result.success).toBe(true)
  })
  
  it("should not buy more than available", () => {
    mockContractCall("create-listing", [1000, 10], "seller1")
    const result = mockContractCall("buy-rec", [1, 1500], "buyer1")
    expect(result.success).toBe(false)
  })
  
  it("should get listing details", () => {
    mockContractCall("create-listing", [1000, 10], "seller1")
    const result = mockContractCall("get-listing", [1], "anyone")
    expect(result.success).toBe(true)
    expect(result.value.amount).toBe(1000)
    expect(result.value["price-per-unit"]).toBe(10)
  })
})

