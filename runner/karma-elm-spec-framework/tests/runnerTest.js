const {expect} = require('chai')
const shell = require('shelljs')
const path = require('path')


describe("karma runner", () => {
  context("some pass, some fail", () => {
    it("shows the expected output", () => {
      const karmaOutput = shell.exec("karma start --single-run", { silent: true })
      expect(karmaOutput.stdout).to.contain("Hey this is a fun log message!")
      expect(karmaOutput.stdout).to.contain("2778")
      expect(karmaOutput.stdout).to.contain("Accepted: 3")
      expect(karmaOutput.stdout).to.contain("Rejected: 2")

      expect(karmaOutput.stdout).to.contain(path.join(__dirname, "../sample/specs/ClickSpec.elm"))
      expect(karmaOutput.stdout).to.contain(path.join(__dirname, "../sample/specs/Behaviors/AnotherSpec.elm"))
    })    
  })
})