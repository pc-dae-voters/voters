# Contact API Client

This folder contains an example Spring Application that accesses Contact API. It comprises a Controller, Service and Feign Client for accessing
the Contact API service. See [contactapiclient](./src/main/java/com/tesco/ise/voters/feign/contactapiclient) package for the example code. This 
comprises a Feign client for the send voters post method and an interceptor to use the Identity service to obtain an authorization token.

To run the spring application set `CLIENT_ID` and `CLIENT_SECRET` to your client id and secret then run the `run.sh` script in the `contact-api` folder.
The default behaviour is to use the production endpoints for identity and contact API services. However, the PPE environment can be selected by passing
the `--ppe` option to the `run.sh` script or setting the `TOKEN_URL` and `CONTACT_API_URL` environmental variables to PPE endpoints.

