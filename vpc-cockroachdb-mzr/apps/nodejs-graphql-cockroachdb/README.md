# mp-graphql-cockroachdb-sample

## Getting Started

- Clone the repo.

- Install all dependencies:

    ```sh
    npm install 
    ```

- Create a build:

    ```sh
    npm run build
    ```

- Copy the `config/cockroach.template.json` to `config/cockroach.json`.

- Modify the `config/cockroach.json` to match your environment:

    ```json
    {
      "address": "<your server>"
    }
    ```

- Build:

    ```sh
    npm run build
    ```

- Run the code:

    ```sh
    npm run start
    ```

Access the server using the url provided in the output screen.