
export function skipTest(t, output, testName, message) {
  t.skip(message)
}

export function expectPassingTest(t, output, testName, message) {
  expectListItemMatches(t, output, `^ok \\d+ ${testName}$`, message)
}

const expectListItemMatches = (t, list, regex, success) => {
  if (list.find(element => element.match(regex))) {
    t.pass(success)
  } else {
    t.fail(`Expected [ ${list} ] to have an item matching: ${regex}`)
  }
}