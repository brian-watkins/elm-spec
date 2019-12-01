const chai = require('chai')
const expect = chai.expect
const Program = require('../src/program')

describe("Find All Programs", () => {
  context("when there are top level spec programs", () => {
    it("finds the program name", () => {
      const testElm = {
        TestOne: fakeSpecProgram(1),
        TestTwo: fakeSpecProgram(2),
        TestThree: fakeSpecProgram(3)
      }
      const programs = Program.discover(testElm)
      expect(programs.map(p => p.id)).to.deep.equal([ 1, 2, 3 ])
    })
  })

  context("when there are nested spec programs", () => {
    it("finds the program names", () => {
      const testElm = {
        TestOne: fakeSpecProgram(1),
        TestTwo: fakeSpecProgram(2),
        Behaviors: {
          BehaviorOne: fakeSpecProgram(3),
          BevaiorTwo: fakeSpecProgram(4),
          OtherBehaviors: {
            SomeOtherBehaviorOne: fakeSpecProgram(6),
            SomeOtherBehaviorTwo: fakeSpecProgram(7)
          }
        },
        TestThree: fakeSpecProgram(5)
      }
      const programs = Program.discover(testElm)
      expect(programs.map(p => p.id)).to.deep.equal([1, 2, 3, 4, 6, 7, 5])
    })
  })
})

const fakeSpecProgram = (id) => {
  return {
    id,
    init: () => {}
  }
}