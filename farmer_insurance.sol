


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "hardhat/console.sol";

contract DisasterData {

    address public admin;
    uint public startDay;

    struct SeverityData {
        uint lastUpdatedDay;
        uint[] values;        // 0-100 indicating intensity
    }

    mapping(string => SeverityData) public severity;


    constructor() {
        admin = msg.sender;
        startDay = block.timestamp / 5 minutes;
    }  





// function -> 1
    function setSeverity(string memory district, uint newSeverity) public { 
        require(msg.sender == admin, "Only admin can set data");
        require(newSeverity<=100, "Severity exceeds max value of 100");
        uint currentDay = block.timestamp / 5 minutes;
        
        uint currentValue;
        if(severity[district].lastUpdatedDay != 0) {
            currentValue = severity[district].values[severity[district].values.length-1];
        }
        else {
            SeverityData memory data;
            data.lastUpdatedDay = startDay-1;
            severity[district] = data;
            currentValue = 0;
        }


        
        for(uint i=severity[district].lastUpdatedDay+1; i<currentDay; i++) {
            severity[district].values.push(currentValue);
        }
        severity[district].values.push(newSeverity);
        severity[district].lastUpdatedDay = currentDay;
    }



 // function -> 2


    function getSeverityData(string memory district, uint day) public view returns (uint){
        require(severity[district].lastUpdatedDay != 0, "Data not present for location");
        require(startDay <= day, "Day should be greater than startDay");
        if(severity[district].lastUpdatedDay > day) return severity[district].values[day-startDay];
        else return severity[district].values[severity[district].values.length-1];
    }




}












//
contract Insurance{

    // Here we make a struct to store the properties/attributes related 
    //to a farmer who shall be a participant as a insurance policy user

    struct Farmer 
    {
        string name;
        string district;
        uint funds_pooled;
        uint timestamp;
        bool eligible_for_claim;
        uint loyalty_points;
        
    }

    // The most elegant would be using mapping for relating farmers with. their addresses

      mapping (address => Farmer) public farmer_info;
      uint total_pool = 0;



// some necessary events for all our functions to keep the logs organised

event Registered(
    address farmer,
    uint ether_amount,
    uint time,
    string district
    );
    
    event Premium_paid(
    address farmer,
    uint ether_amount,
    uint time,
    string district
    );

    event Insurance_claimed(
    address farmer,
    uint ether_amount,
    uint time,
    string district
    );

    
// Our first function for the insurance contract 
// this function will a public one which a farmer is supposed to call initially to register himself for the insurance pool
// they shall be making an initial deposit adding to their fun pool and then making prenium payments accordingly

      function register(string memory _name, string memory _district, uint _funds_to_be_pooled) public payable {
          require(msg.value >= _funds_to_be_pooled);
          //checking if address is already present


        farmer_info[msg.sender].name = _name;
        farmer_info[msg.sender].district = _district;
        farmer_info[msg.sender].funds_pooled += _funds_to_be_pooled;
        farmer_info[msg.sender].timestamp = block.timestamp/5 minutes;
        farmer_info[msg.sender].eligible_for_claim = true;
        farmer_info[msg.sender].loyalty_points = 1;
        
        


        total_pool += get_total_pool();

        emit Registered(msg.sender, msg.value , block.timestamp, 
        _district);


      }

        //here is our premium payment function that a farmer is supposed to call for making a  premium payment
        // even if they make a claim they shall again be allowed to make a claim if keep makign premium  payments
        

      function pay_premium(uint _funds) public payable{
          require(msg.value >= _funds);
          //check if the farmer's address is registered
          //require(farmer_info[msg.sender])
               total_pool= get_total_pool();
               farmer_info[msg.sender].funds_pooled += _funds;
               farmer_info[msg.sender].loyalty_points += 1;
               farmer_info[msg.sender].eligible_for_claim = true;
                farmer_info[msg.sender].timestamp = block.timestamp/ 5 minutes;
          
          

          emit Premium_paid(msg.sender, msg.value , block.timestamp, farmer_info[msg.sender].district);

}


// create a withdrawl option function where only 70 percent of the pool money is given back to the farmer
    
        DisasterData[] private oracles;
        function add_oracles(address newOracle) public{
            oracles.push(DisasterData(newOracle));
        }

        function make_a_claim(uint max_claim) public payable{

          // get the severity score of that district where farmer if from from all oracle instances 
          // average them 
          // if time permits, average them without the outliers
          //payout proportional to loyalty points


          // calculate the total average severity 
          //loyalty points back to zero 

          //x[interator]
          // a boolean named b indicates in every oracle if it's in use or not
          
          uint number_of_oracles = oracles.length;
          console.log("Number of oracles", number_of_oracles);

          uint oracle_sum = 0;
          for ( uint t = 0; t < number_of_oracles ; t++){
              oracle_sum+=oracles[t].getSeverityData(farmer_info[msg.sender].district,block.timestamp/5) ;
          }
            console.log("OracleSum", oracle_sum);

          
          uint final_serverity_score = oracle_sum/number_of_oracles;

            //CHANGE LOGIC

            if(20<= final_serverity_score && final_serverity_score<= 30 ){
                uint money_to_be_compensated = farmer_info[msg.sender].funds_pooled*1;
                farmer_info[msg.sender].funds_pooled = 0;
          farmer_info[msg.sender].eligible_for_claim = false;
          farmer_info[msg.sender].loyalty_points = 0;
          payable(msg.sender).transfer(money_to_be_compensated);
          total_pool = get_total_pool();
           emit Insurance_claimed(msg.sender, msg.value , block.timestamp, farmer_info[msg.sender].district);


            }
            else if(31<= final_serverity_score&& final_serverity_score <= 40){
                
                uint money_to_be_compensated = farmer_info[msg.sender].funds_pooled*2;
                if(money_to_be_compensated >= total_pool){
                    //transact 
                    farmer_info[msg.sender].funds_pooled = 0;
          farmer_info[msg.sender].eligible_for_claim = false;
          farmer_info[msg.sender].loyalty_points = 0;
          payable(msg.sender).transfer(money_to_be_compensated);
          total_pool = get_total_pool();
           emit Insurance_claimed(msg.sender, msg.value , block.timestamp, farmer_info[msg.sender].district);
                }
                else {
                    money_to_be_compensated = total_pool;
                    //compensate the total_pool
                    farmer_info[msg.sender].funds_pooled = 0;
          farmer_info[msg.sender].eligible_for_claim = false;
          farmer_info[msg.sender].loyalty_points = 0;
          payable(msg.sender).transfer(money_to_be_compensated);
          total_pool = get_total_pool();
           emit Insurance_claimed(msg.sender, msg.value , block.timestamp, farmer_info[msg.sender].district);
                }
            }

            else if(40< final_serverity_score && final_serverity_score < 61){
                
                uint money_to_be_compensated = farmer_info[msg.sender].funds_pooled*2;
                if(money_to_be_compensated >= total_pool){
                    //transact 
                    farmer_info[msg.sender].funds_pooled = 0;
          farmer_info[msg.sender].eligible_for_claim = false;
          farmer_info[msg.sender].loyalty_points = 0;
          payable(msg.sender).transfer(money_to_be_compensated);
          total_pool = get_total_pool();
           emit Insurance_claimed(msg.sender, msg.value , block.timestamp, farmer_info[msg.sender].district);
                }
                else {
                     money_to_be_compensated = total_pool;
                    //compensate the total_pool
                    farmer_info[msg.sender].funds_pooled = 0;
          farmer_info[msg.sender].eligible_for_claim = false;
          farmer_info[msg.sender].loyalty_points = 0;
          payable(msg.sender).transfer(money_to_be_compensated);
          total_pool = get_total_pool();
           emit Insurance_claimed(msg.sender, msg.value , block.timestamp, farmer_info[msg.sender].district);
                }
            }
          
          else if(60< final_serverity_score && final_serverity_score< 81){
                
                uint money_to_be_compensated = farmer_info[msg.sender].funds_pooled*2;
                if(money_to_be_compensated >= total_pool){
                    //transact 
                    farmer_info[msg.sender].funds_pooled = 0;
          farmer_info[msg.sender].eligible_for_claim = false;
          farmer_info[msg.sender].loyalty_points = 0;
          payable(msg.sender).transfer(money_to_be_compensated);
          total_pool = get_total_pool();
           emit Insurance_claimed(msg.sender, msg.value , block.timestamp, farmer_info[msg.sender].district);
                }
                else {
                     money_to_be_compensated = total_pool;
                    //compensate the total_pool
                    farmer_info[msg.sender].funds_pooled = 0;
          farmer_info[msg.sender].eligible_for_claim = false;
          farmer_info[msg.sender].loyalty_points = 0;
          payable(msg.sender).transfer(money_to_be_compensated);
          total_pool = get_total_pool();
           emit Insurance_claimed(msg.sender, msg.value , block.timestamp, farmer_info[msg.sender].district);
                }
            }
          else if(80< final_serverity_score ){
                 uint money_to_be_compensated = total_pool;
                 farmer_info[msg.sender].funds_pooled = 0;
          farmer_info[msg.sender].eligible_for_claim = false;
          farmer_info[msg.sender].loyalty_points = 0;
          payable(msg.sender).transfer(money_to_be_compensated);
          total_pool = get_total_pool();
           emit Insurance_claimed(msg.sender, msg.value , block.timestamp, farmer_info[msg.sender].district);
                //compensate total pool

            }
          
          






          

      }

      function get_total_pool() public view returns (uint){
          return address(this).balance;
      }

      function get_owner() public returns (address){
          //owner from oracle 
      }

      function terminate_pool() public pure {
       // returns everyones money back

      }



    

}