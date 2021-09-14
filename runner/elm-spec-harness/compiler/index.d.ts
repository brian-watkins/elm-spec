import Compiler from "elm-spec-core/compiler";

declare class Compiler {
  constructor(options: Compiler.Options)

  compile(): string
  status(): Compiler.Status
}

namespace Compiler {
  export declare interface Options {
    cwd?: string
    harnessPath?: string
    elmPath?: string
    logLevel?: LogLevel
  }
  
  export enum LogLevel {
    ALL, QUIET, SILENT
  }
  
  export enum Status {
    READY, NO_FILES, COMPILATION_SUCCEEDED, COMPILATION_FAILED
  }
}

export default Compiler