# Instructions

1. Open the terminal and add your SSH key
  ```
  ssh-add -k ~./ssh/<YOUR_PRIVATE_KEY>
  ```
1. Navigate to `vpc-multiregion` folder in the repo and create a `.env` file from the template

    ```
     cd vpc-multiregion
     cp template.env .env
    ```
1. Provide the required details in the `.env` file and save.
1. Execute the shell script and follow the steps of execution

  ```
  ./vpc-multiregion-create.sh
  ```
