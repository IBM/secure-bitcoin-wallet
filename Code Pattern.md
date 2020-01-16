Title: Securing a Digital Wallet in the Public Cloud

Summary:
In this code pattern, learn how to deploy a Digital Wallet application with a Web Frontend and an Electrum Bitcoin Client in an IBM Cloud Hyper Protect Virtual Server using [Electrum 3.3.6](https://github.com/spesmilo/electrum/tree/3.3.6). The application will be deployed in an IBM Cloud Hyper Protect Virtual Server while integrating with IBM Cloud Hyper Protect Crypto Services to encrypt the Bitcoin wallet. This integration is optional - but adds another layer of security.

Description:
Cryptocurrencies, such as bitcoin, require top level protection as hackers look to steal these digital assets. Using a digital wallet can be a secure way of keeping cryptocurrency safe. In this example, we can create a digital wallet deployed in the public cloud for easy access while still maintaining high security with IBM Cloud Hyper Protect Services.

To start, we'll create an IBM Cloud Hyper Protect Virtual Server
instance, which requires a generated SSH key pair to ensure only the user has access to the instance. We'll then build and deploy the python backend application. Finally, we'll build and deploy the Electrum Bitcoin a node.js application using
the Express framework to serve a static website employing jQuery to
make requests to the python backend app. This, in turn, can be served
over HTTPS. The result is a donations website that can accept credit
card details, and send some of this sensitive information to a
database, ensuring it's encrypted at all times. By running the
applications on an IBM Cloud Hyper Protect Virtual Server, we can
ensure that the storage used by the applications is also encrypted.

When you've completed this code pattern, you'll know how to:

- Build and run Docker containers
- Deploy a python RESTful interface to a MongoDB database
- Deploy a node.js Express application to serve a static website
- Build and run an Nginx reverse proxy in Cloud Foundry, to provide
  TLS

Flow:
![Disaster donations diagram](./diagram.png)

Instructions:

Find detailed steps for this pattern in the README file
