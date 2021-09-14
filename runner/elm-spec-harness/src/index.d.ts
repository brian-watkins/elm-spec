export declare function prepareHarness<T>(moduleName: string): Harness<T>

export declare function onObservation(handler: (observation: Observation) => void): void

export declare function onLog(handler: (report: Report) => void): void

export declare type Observation = Accepted | Rejected

export declare interface Accepted {
  description: string
  summary: "ACCEPTED"
}

export declare interface Rejected {
  description: string
  summary: "REJECTED"
  report: Report
}

export declare type Report =
  Array<{ statement: string, detail: string | null }>


export declare class Harness<T> {
  getElmApp(): T
  startScenario(name: string, config: any = null): Promise<Scenario>
  stopScenario(): void
}

export declare class Scenario {
  wait(): Promise<void>
  runSteps(name: string, config: any = null): Promise<void>
  observe(name: string, config: any, description: string): Promise<void>
}