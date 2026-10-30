/******
 * Class Name - Calculator
 * Author - Prakash
 * Date - 30th Oct 2026
 * 
 */
/*************************************************************************
 * Version      Date        Name        Description
 * *************************************************
 * v0.1         31 Oct 26   Developer1  Add method
 * v0.2         31 Oct 26   Developer2  Sub method
 * 
 **************************************************************************/
public with sharing class Calculator {
    public Calculator() {
}
    public Integer addition(integer a , integer b){
        return a+b;
    }
    public integer substraction(integer a, Integer b){
        return a-b;
    }
}