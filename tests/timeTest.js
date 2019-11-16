const { expectPassingSpec } = require("./helpers/SpecHelpers")


describe("time plugin", () => {
  describe("when the program is a worker program in node", () => {
    it("allows the spec to control Time.every as necessary", (done) => {
      expectPassingSpec("TimeSpec", "", done)
    })
  
    describe("when the program uses Process.sleep", () => {
      it("processes the command as expected", (done) => {
        expectPassingSpec("SleepSpec", "sleep", done)
      })
  
      it("processes only tasks that have occured during the ticks", (done) => {
        expectPassingSpec("SleepSpec", "delay", done)
      })
    })
  })
  
  describe("when the program is a browser program", () => {
    it("allows the spec to control Time.every as necessary", (done) => {
      expectPassingSpec("HtmlTimeSpec", "interval", done)
    })
  })
})