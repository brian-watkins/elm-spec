# Elm-Spec Core

This library contains the core logic for running elm-spec suites. Runner applications
can use this library to run elm-spec suites in a particular environment.

### API

Four modules are exposed:

- Compiler: compiles the specified spec files
- ElmContext: manages the window and test environment
- SuiteRunner: Executes all compiled spec programs
- ProgramRunner: Executes one spec program

### Basic Usage

1. Create an ElmContext, given a DOM window object. 
2. Use the Compiler to compile the code and evaluate it in the DOM window.
3. Provide the ElmContext and a Spec Reporter to the SuiteRunner to run all the specs
