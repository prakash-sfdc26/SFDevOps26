public with sharing class UserInfoHandler {

    @InvocableMethod(label='User info Action'
                     description='Return current Logged in user Details. For example when user ask what is my name or Brief me about myself')
    public static List<String> getUserDetails(List<String> userName) {
        User currentUser = [SELECT Name, CompanyName, EmployeeNumber, UserRole.Name FROM User
                            WHERE Id = :UserInfo.getUserId() LIMIT 1];

        String response = 'Here are the Details about the User:- User Name: ' + currentUser.Name
            + ' Company Name: ' + currentUser.CompanyName
            + ' Employee Number: ' + currentUser.EmployeeNumber
            + ' User Role: ' + currentUser.UserRole?.Name; // role is optional

        // Invocable methods must return one result per input
        Integer count = (userName == null || userName.isEmpty()) ? 1 : userName.size();
        List<String> responses = new List<String>();
        for (Integer i = 0; i < count; i++) {
            responses.add(response);
        }
        return responses;
    }
}