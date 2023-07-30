 # royal-holiday-challange

 ## ANSWER TO QUESTION 3
 How would you validate the terraform or CDK code for the above workload (question 2), to avoid errors during the apply phase?
 
 * To validate: terraform validate
 * To prevent errors: Use terraform plan -out=<resulting_plan>
 * To reduce even more the possibility of errors: Use a different AWS account (different credentials) as a pre-deploy stage deploy the changes there in order to validate the results before promoting them into the main stage (prod)   


## ANSWER TO QUESTION 4
 Explain how you would monitor the above workload (question 2).What metrics (Golden Signals) do you consider most important to monitor?

 The most important signals to monitor for this application would be traffic and errors, given that it is a self container application, the latency should not vary too much, we can even cached it or even mock it (but just because it is an example). The number of errors is a metric that should be observed as it might indicate a problem with the containers or the network. While traffic might gives us the hint of a DDoS attack. 

 Develop a basic idea using AWS CloudWatch Metrics or another monitoring product you are familiar with.
 
 We could check the ALB access logs with a data analysis tool/service to review, like AWS Athena. 


 ## ANSWER TO QUESTION 5
 If you have the need to implement a rollback for the previous deployment service, explain how you can build it.
 First, I would implement a Canary or Blue/Green deployment strategy, so we could reduce the downtime or at least the percentage of tasks running the version that we want to rollback.
 
 And given that we cannot use the previous revision and it seems like we want to use GitFLow for this, we could opt to use the 'git revert' command to go back to the previous (or desired commit) while maintaing the history or commits and then push to master and deploy the previous code.      

