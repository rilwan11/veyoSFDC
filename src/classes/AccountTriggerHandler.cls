/**
 * Created by krizia on 11/10/17.
 */

public with sharing class AccountTriggerHandler {
    //Manage Trigger to prevent second firing when Account is updated within this class
    public static boolean firstRun = true;


    /**
    * Krizia: whenever a Default Account Email Address is added, make it a contact in order to send emails from Grievances
    */
    public static void defaultEmailAddressContact(List<Account> aList) {
        //Go through list to first find out if they have a Default Account Email Address
        List<String> emailList = new List<String>();
        for (Account a : aList) {
            if (a.Default_Account_Email_Address__c != null) {
                emailList.add(string.valueOf(a.Default_Account_Email_Address__c));
            }
        }

        //Now find out if those email addresses already are Contacts
        List<Contact> contacts = new List<Contact>();
        contacts = [ SELECT Id, Name, Email
                        FROM Contact
                        WHERE Email IN :emailList ];

        System.debug('AccountTriggerHandler::: defaultEmailAddressContact:: contacts: ' + string.valueOf(contacts));

        //Make new contacts for all emails that don't already have one
        List<Contact> insertContacts = new List<Contact>();
        for (String e : emailList) {
            boolean alreadyC = false;
            System.debug(e);

            if (contacts.size() > 0) {
                for (Contact c : contacts) {
                    //Mark if this email is already present
                    System.debug(c.Email);
                    if (String.valueOf(c.Email) == e) {
                        System.debug('AccountTriggerHandler::: defaultEmailAddressContact:: email with contact exists');
                        alreadyC = true;
                    }
                }
                //Make a new Contact if there isn't already one
                if (alreadyC == false) {
                    Contact newC = new Contact(FirstName = 'Default Account', LastName = 'Email Address', Email = e);
                    System.debug('AccountTriggerHandler::: defaultEmailAddressContact:: New Default Account Email Address contact: ' + string.valueOf(newC));
                    insertContacts.add(newC);
                }
            }
            else { //Make a new Contact straight up for each email when there aren't already contacts
                Contact newC = new Contact(FirstName = 'Default Account', LastName = 'Email Address', Email = e);
                System.debug('AccountTriggerHandler::: defaultEmailAddressContact:: New Default Account Email Address contact when contact list is empty: ' + string.valueOf(newC));
                insertContacts.add(newC);
            }

        }


        //Insert all new contacts
        if (insertContacts.size() > 0) {
            insert insertContacts;
        }

    } //public static void defaultEmailAddressContact(List<Account> aList)

}