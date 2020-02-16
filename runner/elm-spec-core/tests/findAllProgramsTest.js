const chai = require('chai')
const expect = chai.expect
const ProgramReference = require('../src/programReference')

describe("Find All Programs", () => {
  context("when there are top level spec programs", () => {
    it("finds the program name", () => {
      const testElm = {
        TestOne: fakeSpecProgram(1),
        TestTwo: fakeSpecProgram(2),
        TestThree: fakeSpecProgram(3)
      }
      const programs = ProgramReference.findAll(testElm)

      expect(programs.map(p => p.moduleName)).to.deep.equal([
        [ "TestOne" ],
        [ "TestTwo" ],
        [ "TestThree" ]
      ])
      expect(programs.map(p => p.program.id)).to.deep.equal([ 1, 2, 3 ])
    })
  })

  context("when there are nested spec programs", () => {
    it("finds the program names", () => {
      const testElm = {
        TestOne: fakeSpecProgram(1),
        TestTwo: fakeSpecProgram(2),
        Behaviors: {
          BehaviorOne: fakeSpecProgram(3),
          BehaviorTwo: fakeSpecProgram(4),
          OtherBehaviors: {
            SomeOtherBehaviorOne: fakeSpecProgram(6),
            SomeOtherBehaviorTwo: fakeSpecProgram(7)
          }
        },
        TestThree: fakeSpecProgram(5)
      }
      const programs = ProgramReference.findAll(testElm)

      expect(programs.map(p => p.moduleName)).to.deep.equal([
        [ "TestOne" ],
        [ "TestTwo" ],
        [ "Behaviors", "BehaviorOne" ],
        [ "Behaviors", "BehaviorTwo" ],
        [ "Behaviors", "OtherBehaviors", "SomeOtherBehaviorOne" ],
        [ "Behaviors", "OtherBehaviors", "SomeOtherBehaviorTwo" ],
        [ "TestThree" ]
      ])
      expect(programs.map(p => p.program.id)).to.deep.equal([1, 2, 3, 4, 6, 7, 5])
    })
  })
})

const fakeSpecProgram = (id) => {
  return {
    id,
    init: () => {}
  }
}