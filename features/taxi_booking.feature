Feature: Taxi booking
  As a customer
  Such that I go to destination
  I want to arrange a taxi ride

  Scenario: Booking via STRS' web page (with confirmation)
    Given the following taxis are on duty
      | username             | location	     | status    | capacity | price |
      | peeter88@example.com | Juhan Liivi 2 | BUSY      | 4        | 1.8   |
      | juhan85@example.com  | Kalevi 4      | AVAILABLE | 3        | 1.2   |
    And I want to login with username "test@example.com" and password "12345678"
      And I open the login page
      And I enter the login information
      When I submit the login information
      Then I should receive a welcome message
    And I want to go from "Juhan Liivi 2" to "Muuseumi tee 2"
      And I open STRS' web page
      And I enter the booking information
      When I summit the booking request
      Then I should receive a confirmation message

  Scenario: Booking via STRS' web page (with rejection)
    Given the following taxis are on duty
      | username              | location  | status | capacity | price |
      | juhan85@example.com   | Kaubamaja | BUSY   | 4        | 1.8   |
      | peeter88@example.com  | Kaubamaja | BUSY   | 3        | 1.2   |
    And I want to login with username "test@example.com" and password "12345678"
      And I open the login page
      And I enter the login information
      When I submit the login information
      Then I should receive a welcome message
    And I want to go from "Liivi 2" to "Lõunakeskus"
      And I open STRS' web page
      And I enter the booking information
      When I summit the booking request
      Then I should receive a rejection message
