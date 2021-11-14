# How to do contract testing?

Given that one has an API contract document (like an OpenApi document), there are several
things one could do. 

1. Generate code base on the contract, which should become the only way that the program
interacts with the API.
2. Create a mock server based on the contract, which should be used during tests. Usually
this server will return responses based on examples found in the OpenAPI document or generate
random responses.
3. Use the contract to validate stubs during tests.

Elm-spec will support (3). 

Option 1 is cool but of course not something elm-spec should ever do. Option 2 is interesting
but I'd like to have control over the exact values in the responses used during tests and be
able to tune them on a per-test basis as necessary.

So Option 3 seems to give me the most control as a test writer to write the tests that I need
while also feeling confident that I'm not accidentally drifting away from the api contract.


### Implementation

We decided to use some existing JS tools to do the validation. While it would be nice to do
this all in Elm, I think a lot of work would be necessary for that to happen.

We decided to use packages from [this repo](https://github.com/kogosoftwarellc/open-api)
since it provides smaller building blocks to compose into an OpenAPI framework. It seems
to work find with OpenAPI 2 and 3; not sure about support for 3.1 ...

These tools don't seem to support validating headers on the response; I'm not sure why or
if I just couldn't figure out the pattern. In any case, we also had to bring in AJV to handle
validation of reponse headers. If necessary, it seems like we could extend this pattern
to just continue using AJV as the validator and the code we write is just to provide it the
relevant parts of the OpenApi doc (this is basically what the tools we are using do I think).

We decided to allow each `Stub` to specify a contract that it satisfies. This makes it easy
to describe stubs with different contracts or some stubs that should not be validated.

### Future

It would be cool one day to do the validation in Elm, but seems like it would require
some significant work. Some thoughts:

- Should we load the OpenApi doc text file? Then we need both a YAML and JSON parser in Elm.
Not sure if any of the YAML parser implementations are full-featured enough. To simplify this
could parse the file on the JS side and send in a JSON value to be parsed on the Elm side.
- We need json schema validation in Elm. There is a json-schema package but it hasn't been
worked on in years and says that it's incomplete.
- Then we would need code to run the relevant parts of the contract through json schema validation.

Probably getting a json schema validation working is the hardest part.