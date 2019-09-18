const chai = require('chai')
const expect = chai.expect
const { expectSpec } = require("./helpers/SpecHelpers")

describe("list observers", () => {
  describe("hasLength", () => {
    it("uses the hasLength observer as expected", (done) => {
      expectSpec("ListObserverSpec", "hasLength", done, (observations) => {
        expect(observations[0].summary).to.equal("ACCEPT")
        expect(observations[1].summary).to.equal("REJECT")
        expect(observations[1].report).to.deep.equal([{
          statement: "Expected list to have length",
          detail: "3"
        },{
          statement: "but it has length",
          detail: "1"
        }])
      })
    })
  })
})