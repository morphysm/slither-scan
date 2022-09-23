/**
 *Submitted for verification at snowtrace.io on 2022-01-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.11;

contract DAO{
	address ORACLE = address(0);
	address address0 = address(0);
    address THIS = address(this);

	struct RequestTicket{
		uint ID;
		address sender;
		uint timeRequested;
		uint timeWindow;
		bool finalized;
		uint serviceFee;
		bool subjective;

		mapping(address => mapping(address => bool)) attacks;
		mapping(address => bool) damaged;

		uint8 dataType; // uint, address

		//commit
		mapping(address => bool) committed;
		mapping(address => bytes32) commitHash;

		//reveal
		mapping(address => bool) revealed;
		mapping(address => bool) rejected;
		mapping(address => bool) voted;

		mapping(address => int) intVotes;
		mapping(address => address) addressVotes;

		//RESULTS
		bool ticketRejected;
		uint numberOfOptions;
		
		//results
		mapping(uint => uint) weightOfResults;
		mapping(uint => int) resolvedInts;
		mapping(uint => address) resolvedAddresses;
	}

	//oracle configs
	uint constant ROUNDTABLE_SEATS = 0;
	uint constant RESPONSE_TIME_WINDOW = 1;
	uint constant DELEGATE_REWARDSHARE = 2;
	uint constant FREEZE_TIMEOUT = 3;
	uint constant SERVICE_FEE = 4;
	uint constant TX_FEE_PER = 5;
	uint constant CONFIGS = 6;

	uint[] public oracleConfigurations = new uint[](CONFIGS);
	
	mapping(address => uint) resolveWeight;
	mapping(address => uint) weightLocked;
	
	mapping(uint => RequestTicket) requestTickets;
	uint requestTicketCount;
	//ROUND TABLE & Candidates
	mapping(uint => address) public chairsCandidate; // only looks at the first X indexes
	mapping(address => uint) candidatesChair;
	mapping(address => uint) timeSeated; // watchers aren't responsible for requestTickets that came in before them
	mapping(address => bool) frozen;
	mapping(address => bool) isWatcher;
	mapping(address => uint) latestPunishment;
	mapping(address => uint) timeWhenThawedOut;
	uint chairs;
	uint public hotSeats;

	uint256 constant scaleFactor = 0x10000000000000000;
	//PAYROLL
	mapping(address => uint) earnings;
	mapping(address => uint) totalShares;
    mapping(address => mapping(address => uint256)) public shares;
    mapping(address => mapping(address => uint256)) payouts;
    mapping(address => uint) earningsPerShare;

    //Tx Coverage fee
    uint earningsPerWatcher;
	uint public totalWatchers;
	mapping(address => uint256) watcherPayouts;


    //lazy UI data
    mapping(address => address[]) public yourBacking;
    mapping(address => mapping(address => bool)) public alreadyBacking;
    
	ResolveToken public resolveToken;
	address payable pineapples;
	Pyramid public pyramid = Pyramid(0x520E6986f7E7EBfB6e15F753F3230eDb4dC2432f);
	uint genesis;

	ERC20 $MM = ERC20(0x993163CaD35162fB579D7B64e6695cB076EF5064);
	
	constructor(){
		resolveToken = pyramid.resolveToken();
		genesis = _now();
		pineapples = payable(msg.sender);

		freshConfigs();
		registered[address(this)] = true;
	}

	uint lastTimeTicketWasFinalized;
    function failSafe() public{
    	if(_now() - lastTimeTicketWasFinalized > 43200){
    		freshConfigs();
    	}
    }

    function freshConfigs() internal{
    	lastTimeTicketWasFinalized = _now();
    	hotSeats = 7;
		oracleConfigurations[ROUNDTABLE_SEATS] = 7;
		oracleConfigurations[RESPONSE_TIME_WINDOW] = 60*5;
		oracleConfigurations[DELEGATE_REWARDSHARE] = 25*1e18;
		oracleConfigurations[FREEZE_TIMEOUT] = 86400;
		oracleConfigurations[SERVICE_FEE] = 0;
		oracleConfigurations[TX_FEE_PER] = 0;
    }

	function _now()internal view returns(uint){
		return block.timestamp;
	}

	function addShares(address pool, address account, uint amount) internal{
		update(pool, account);
		totalShares[pool] += amount;
		shares[pool][account] += amount;

		if(pool == ORACLE){
			updateWatcherTxEarnings(account,false);
			if (account != address0){
				totalWatchers += 1;
				isWatcher[account] = true;
			}
		}
	}

	function removeShares(address pool, address account, uint amount) internal{
		update(pool, account);
		totalShares[pool] -= amount;
		shares[pool][account] -= amount;

		if(pool == ORACLE){
			updateWatcherTxEarnings(account,true);
			if (account != address0){
				isWatcher[account] = false;

				uint emptiedSeat = candidatesChair[account];

				address tail = chairsCandidate[totalWatchers-1];
				chairsCandidate[ emptiedSeat ] = tail;
				candidatesChair[tail] = emptiedSeat;

				totalWatchers -= 1;
			}
		}
	}

	function dividendsOf(address pool, address account) public view returns(uint){
		uint owedPerShare = earningsPerShare[pool] - payouts[pool][account];
		if(pool == ORACLE && !isWatcher[account] )
			return 0;
		return shares[pool][account] * owedPerShare / scaleFactor;
	}
	
	
	event WatcherPayroll(address watcher, uint paidOut);	
	function update(address pool, address account) internal {
		uint newMoney = dividendsOf(pool, account);
        payouts[pool][account] = earningsPerShare[pool];

		if(pool == ORACLE){
			uint eth4Watcher = newMoney * oracleConfigurations[DELEGATE_REWARDSHARE] / (1e20);
			earnings[account] += eth4Watcher;

			uint newDivs;
			if(totalShares[account]>0){
				newDivs = (newMoney - eth4Watcher) * scaleFactor / totalShares[account];
			}else{
				newDivs = 0;
			}

			earningsPerShare[account/*this is what the watcher has to distribute to its electorates*/] += newDivs;
		}else{
			earnings[account] += newMoney;
		}
    }

	event TxCashout(address watcher, uint amount);
	function updateWatcherTxEarnings(address watcher, bool paying) internal {
		uint owed = earningsPerWatcher - watcherPayouts[watcher];
		watcherPayouts[watcher] = earningsPerWatcher;
		if(paying) earnings[watcher] += owed;
		emit TxCashout(watcher, owed);
    }

	event StakeResolves( address indexed addr, uint256 amountStaked, bytes _data );
	function tokenFallback(address from, uint value, bytes calldata _data) external{
		if( msg.sender == address(resolveToken) ){
			if(from == address(pyramid)){
				return;// if the pyramid is sending resolve tokens back to this contract, then do nothing.
			}
			resolveWeight[from] += value;

			emit StakeResolves(from, value, _data);
			
			address backImmediately = bytesToAddress( _data );

			if( backImmediately != address0){
				backCandidate(from, backImmediately, value);
			}

		}else{
			revert();
		}
	}

	event UnstakeResolves(address sender, uint amount);
	function unstakeResolves(uint amount) public{
		address sender = msg.sender;
		if( amount <= ( resolveWeight[sender] - weightLocked[sender] ) ){
			resolveWeight[sender] -= amount;

			emit UnstakeResolves(sender, amount);

			resolveToken.transfer(sender, amount);
		}else{
			revert();
		}
	}

	event BackCandidate(address sender,address candidate, uint amount);
	function stakeCandidate(address candidate, uint amount) public{ backCandidate(msg.sender, candidate, amount); }
	function backCandidate(address sender, address candidate, uint amount) internal{
		require(candidate!=ORACLE);
		if( amount <= ( resolveWeight[sender] - weightLocked[sender] ) && !frozen[candidate] && !isWatcher[candidate] ){
			weightLocked[sender] += amount;
			addShares(candidate, sender, amount);

			emit BackCandidate(sender, candidate, amount);
			//LAZY U.I.
			if(!alreadyBacking[sender][candidate]){
				yourBacking[sender].push(candidate);
				alreadyBacking[sender][candidate] = true;
			}
		}else{
			revert();
		}	
	}
	
	event PullBacking(address sender, address candidate, uint amount);
	function pullBacking( address candidate, uint amount ) public{
		address sender = msg.sender;
		if( amount <= shares[candidate][sender] && !frozen[candidate] && !isWatcher[candidate] ){
			weightLocked[sender] -= amount;
			removeShares(candidate, sender, amount);
			emit PullBacking(sender, candidate, amount);
		}else{
			revert();
		}
	}

	function pullAllTheWay(address candidate, uint amount) public{
		pullBacking(candidate, amount);
		unstakeResolves(amount);
	}

	event AssertCandidate(address candidate, bool successfulAssert, address replacedWatcher, uint newSeat);
	function assertCandidate() public returns(bool success){
		address candidate = msg.sender;
		uint weakestChair;
		bool nullSeat;
		require( !frozen[candidate] && hotSeats > 0);
		address thisWatcher;

		if(hotSeats == totalWatchers){
			for(uint i; i<hotSeats; i+=1){
				thisWatcher = chairsCandidate[i];
				if( totalShares[ thisWatcher ] < totalShares[ chairsCandidate[weakestChair] ] ){
					weakestChair = i;
				}
			}
		}else{
			nullSeat = true;
			weakestChair = totalWatchers;
		}

		if( (totalShares[candidate] > totalShares[ chairsCandidate[weakestChair] ] || nullSeat ) && !isWatcher[candidate] ){
			address targetCandidate = chairsCandidate[weakestChair];

			if(!nullSeat){
				removeShares(ORACLE, targetCandidate, totalShares[targetCandidate]);
			}else{
				targetCandidate = address0;
			}

			addShares(ORACLE, candidate, totalShares[candidate]);
			timeSeated[candidate] = _now();

			chairsCandidate[weakestChair] = candidate; 
			candidatesChair[candidate] = weakestChair;

			emit AssertCandidate(candidate, true, targetCandidate, weakestChair);
			return true;
		}

		emit AssertCandidate(candidate, false, address0, weakestChair);
		return false;
	}


	//mapping(uint => uint) internalRequestID;
	mapping(uint => bool) internalRequestType;
	mapping(uint => uint8) configType;
	mapping(uint => uint) configSetting;
	event OracleConfigRequest(uint8 config, uint setting, uint indexed ticketID);
	function oracleConfigRequest(uint8 config, uint setting, uint msgValue) public returns(uint ticketID){
		require(config<CONFIGS && $MM.transferFrom(msg.sender, THIS, msgValue) );
		ticketID = this.fileRequestTicket(1,true,msgValue);
		configType[ticketID] = config;
		configSetting[ticketID] = setting;
		emit OracleConfigRequest(config, setting, ticketID);
	}

	mapping(uint => address) requestedContract;
	mapping(address => bool) public registered;
	event OracleJobRequest(string description, address _contract, bool updatedState , uint indexed ticketID);
	function oracleJobRequest(string memory description, address _contract, bool updatedState, uint msgValue) public returns(uint ticketID){
		require( $MM.transferFrom(msg.sender, THIS, msgValue) );
		ticketID = this.fileRequestTicket(1,true,msgValue);
		internalRequestType[ticketID] = true;
		configSetting[ticketID] = updatedState?1:0;
		requestedContract[ticketID] = _contract;
		emit OracleJobRequest(description, _contract, updatedState, ticketID);
	}

	event jobNotUpdated(address _contract, uint indexed ticketID);
    event jobUpdated(address _contract, bool updatedState, uint indexed ticketID);
	event configRejected(uint8 _configType, uint _configSetting, uint indexed ticketID);
    event configAccepted(uint8 _configType, uint _configSetting, uint indexed ticketID);
    function oracleIntFallback(uint ticketID, bool EXCEPTION, uint numberOfOptions, uint[] memory optionWeights, int[] memory intOptions) public{
        uint optWeight;
        uint positive;
        uint negative;
        require( msg.sender == address(this) );

        if(!EXCEPTION){
	        //YES OR NO?
	        for(uint i; i < numberOfOptions; i+=1){
	            optWeight = optionWeights[i];
	            if(intOptions[i]>0){
	                positive += optWeight;
	            }else{
	                negative += optWeight;
	            }
	        }

	        if(internalRequestType[ticketID]){
	        	address _requestedContract = requestedContract[ticketID];
	        	bool updatedState = configSetting[ticketID]>0;
	        	if(positive>negative){
	        		registered[_requestedContract] = updatedState;
	            	emit jobUpdated(_requestedContract, updatedState, ticketID);	
	            }else{
	            	emit jobNotUpdated(_requestedContract, ticketID);
	            }
    		}else{
	        	uint8 _configType = configType[ticketID];
	        	uint _configSetting = configSetting[ticketID];

	        	if(positive>negative){
	        		
					if(_configType == RESPONSE_TIME_WINDOW){ _configSetting = _configSetting>180?_configSetting:180; }
					if(_configType == ROUNDTABLE_SEATS){
					 _configSetting = _configSetting>7?_configSetting:7;
					}
					if(_configType == DELEGATE_REWARDSHARE){ _configSetting = _configSetting>1e20?1e20:_configSetting; }

					oracleConfigurations[_configType] = _configSetting;

					if(_configType == ROUNDTABLE_SEATS){
						if(hotSeats<oracleConfigurations[ROUNDTABLE_SEATS]){
							hotSeats = oracleConfigurations[ROUNDTABLE_SEATS];
						}
					}

	            	emit configAccepted(_configType, _configSetting, ticketID);	
	            }else{
	            	emit configRejected(_configType, _configSetting, ticketID);
	            }
    		}
        }
    }


	function getFee() public view returns(uint txCoverageFee, uint serviceFee){
		return ( oracleConfigurations[TX_FEE_PER]*hotSeats, oracleConfigurations[SERVICE_FEE] );
	}

	uint public devFunds;
	function updatePines(address addr) public{
		require(msg.sender == pineapples);
		pineapples = payable(addr);
	}

	function devPull() public{
		require(msg.sender == pineapples);
		uint money = devFunds;
		devFunds = 0;
		payable(msg.sender).transfer( money );
	}

	
	mapping(address => address) public useCaseBank;
	mapping(address => uint) public partnerRewards;

	function newPartnership(address usecase, address partner) public {
		require(msg.sender == pineapples && useCaseBank[usecase] == address0);
		useCaseBank[usecase] = partner;
	}

	function payPartner(address partner) public{
		require( partnerRewards[partner] > 0 );
		uint money = partnerRewards[partner];
		partnerRewards[partner] = 0;
		payable(partner).transfer( money );
	}

	//------------------------------ Request Ticket Life Cycle
	event FileRequestTicket(address sender, uint ticketID, uint8 dataType, bool subjective, uint timeRequested, uint responseTimeWindow, uint feePaid);
	function fileRequestTicket( uint8 returnType, bool subjective, uint msgValue) public returns(uint ticketID){
		address sender = msg.sender;
		require( $MM.transferFrom(sender, THIS, msgValue) || sender == THIS );
		(uint txCoverageFee, uint serviceFee) = getFee();
		
		uint devFee = serviceFee/20;

		require( (returnType == 1 || returnType == 0) && registered[sender] );

		if(msgValue >= txCoverageFee + serviceFee + devFee){

			ticketID = requestTicketCount;
			RequestTicket storage ticket = requestTickets[requestTicketCount];
			requestTicketCount++;

			ticket.dataType = returnType;
			ticket.timeRequested = _now();
			ticket.timeWindow = oracleConfigurations[RESPONSE_TIME_WINDOW];
			ticket.ID = ticketID;
			ticket.sender = sender;
			ticket.subjective = subjective;
			ticket.serviceFee = msgValue - devFee - txCoverageFee;

			if( useCaseBank[sender] != address0 ){
				devFunds += devFee/10; // 0.5%
				partnerRewards[ useCaseBank[sender] ] += devFee - devFee/10; // 4.5%
			}else{
				devFunds += devFee;
			}

			earningsPerWatcher += txCoverageFee / totalWatchers;

			emit FileRequestTicket(msg.sender, ticketID, returnType, subjective, _now(), ticket.timeWindow, msgValue);
		}else{
			revert();
		}
	}

	event CommitVote(address voter, uint ticketID, bytes32 hash);
	function commitVote(uint[] memory tickets, bytes32[] memory voteHashes) external{
		address sender = msg.sender;
		RequestTicket storage ticket;
		for(uint R; R<tickets.length; R+=1 ){
			ticket = requestTickets[ tickets[R] ];
			if( _now() <= ticket.timeRequested + ticket.timeWindow ){
				ticket.committed[sender] = true;
				ticket.commitHash[sender] = voteHashes[R];
				emit CommitVote(sender, tickets[R], voteHashes[R]);
			}else{
				revert();//outside of timewindow
			}
		}
	}
	
	event RevealVote(address voter, uint ticketID, bool rejected, int intVote, address addressVote, string comments);
	function revealVote(uint[] memory tickets, bool[] memory rejected, int[] memory intVotes, address[] memory addressVotes, uint[] memory passwords, string memory comments) external{
		address sender = msg.sender;
		RequestTicket storage ticket;
		bytes memory abiEncodePacked;
		for(uint R; R<tickets.length; R+=1 ){
			ticket = requestTickets[ tickets[R] ];
			if( ticket.committed[sender] ){
				if(_now() > ticket.timeRequested + ticket.timeWindow && _now() <= ticket.timeRequested + ticket.timeWindow*2 ){
					if(ticket.dataType == 1){
						abiEncodePacked = abi.encodePacked( rejected[R], intVotes[R], passwords[R] );
					}else if(ticket.dataType == 0){
						abiEncodePacked = abi.encodePacked( rejected[R], addressVotes[R], passwords[R] );
					}

					if( compareBytes( keccak256(abiEncodePacked), requestTickets[ tickets[R] ].commitHash[sender]) ){

						requestTickets[ tickets[R] ].revealed[sender] = true;
						if(rejected[R]){
							requestTickets[ tickets[R] ].rejected[sender] = true;
						}else{
							requestTickets[ tickets[R] ].voted[sender] = true;
							if(ticket.dataType == 1){
								requestTickets[ tickets[R] ].intVotes[sender] = intVotes[R];
							}else if(ticket.dataType == 0){
								requestTickets[ tickets[R] ].addressVotes[sender] = addressVotes[R];
							}	
						}
						emit RevealVote(sender, tickets[R], rejected[R], intVotes[R], addressVotes[R], comments);
					}else{
						revert();//not a match
					}
				}else{
					revert();//outside of timewindow
				}
			}
		}
	}

	event SubjectiveStance(address voter, uint ticketID, address defender, bool stance);
	function subjectiveStance(uint[] memory tickets, address[] memory defenders, bool[] memory stances) external{
		address sender = msg.sender;
		RequestTicket storage ticket;
		for(uint R; R<tickets.length; R+=1 ){
			ticket = requestTickets[ tickets[R] ];
			if(timeSeated[sender] <= ticket.timeRequested){
				if( timeSeated[defenders[R]] <= ticket.timeRequested && _now() > ticket.timeRequested + ticket.timeWindow*2 && _now() <= ticket.timeRequested + ticket.timeWindow*3 ){
					ticket.attacks[sender][defenders[R]] = stances[R];
					emit SubjectiveStance(sender, tickets[R], defenders[R], stances[R]);
				}else{
					revert();//outside timewindow
				}
			}else{
				revert();//you just got here homie, whatcha takin' shots for?
			}
		}
	}

	function calculateDamage( uint ticketID ) internal view returns(uint combatWeight, uint[] memory damage){
		RequestTicket storage ticket = requestTickets[ticketID];
		address offensiveWatcher;
		address defender;
		uint Y;
		uint X;
		damage = new uint[](hotSeats);
		if(ticket.subjective){
			for(X = 0; X < hotSeats; X+=1){
				offensiveWatcher = chairsCandidate[X];
				if( isWatcher[offensiveWatcher] && timeSeated[offensiveWatcher] <= ticket.timeRequested ){
					combatWeight += totalShares[offensiveWatcher];
					for(Y = 0; Y < hotSeats; Y+=1){
						defender = chairsCandidate[Y];
						if( isWatcher[defender] && timeSeated[defender] <= ticket.timeRequested){
							if(ticket.attacks[offensiveWatcher][defender]){
								damage[Y] += totalShares[offensiveWatcher];
							}
						}
					}	
				}
			}
		}
	}

	event FinalizedRequest(uint ticketID, address[] watchers);
	function finalizeRequests(uint[] memory tickets) external{
		for(uint R; R<tickets.length; R+=1 ){
			finalizeRequest( tickets[R] );
		}
	}
	
	function finalizeRequest(uint ticketID) public{
		// if response time window is over or all delegates have voted,
		// anyone can finalize the request to trigger the event
		RequestTicket storage ticket = requestTickets[ticketID];
		if(!ticket.finalized){
			
			address watcher;
			
			int[] memory intOptions = new int[](hotSeats);
			address[] memory addressOptions = new address[](hotSeats);
			uint[] memory optionWeights = new uint[](hotSeats);

			address[] memory watchers = new address[](hotSeats);// lazy UI data

			uint[] memory UINTs = new uint[](7);//0= weight of votes, 1=top Option, 2= number of options, 3=top Option, 4 =total eligible weight, 5 = combat weight, 6  = loop for saving subjectives to storage

			uint opt;
			uint[] memory damage;
			(UINTs[5]/*combatWeight*/, damage) = calculateDamage(ticketID);
			for(uint chair = 0; chair < hotSeats; chair+=1){
				watcher = chairsCandidate[chair];
				watchers[chair] = watcher;
				if(damage[chair]<=UINTs[5]/*combatWeight*//2){
					if( watcher!=address0 && isWatcher[watcher] && timeSeated[watcher] <= ticket.timeRequested && ticket.revealed[watcher] ){
						UINTs[4]/*total Eligible Weight*/ += totalShares[watcher];
						if( ticket.voted[watcher] ){
							UINTs[0]/*weight of votes*/ += totalShares[watcher];
							//check to see if chosen option already is accounted for, if so, add weight to it.
							for(opt = 0; opt<UINTs[2]/*option count*/; opt+=1){
								if( (ticket.dataType == 1 && intOptions[opt] == ticket.intVotes[watcher]) ||
									(ticket.dataType == 0 && addressOptions[opt] == ticket.addressVotes[watcher]) 
								){
									optionWeights[opt] += totalShares[watcher];
									if(optionWeights[opt] > optionWeights[UINTs[3]/*top option*/] && !ticket.subjective){
										UINTs[3]/*top option*/ = opt;
									}
									break;
								}
							}

							//add new unique option
							if(opt == UINTs[2]/*option count*/){
								if(ticket.dataType == 1){
									intOptions[UINTs[2]/*option count*/] = ticket.intVotes[watcher];
								}else if(ticket.dataType == 0){
									addressOptions[UINTs[2]/*option count*/] = ticket.addressVotes[watcher];
								}
								optionWeights[UINTs[2]/*option count*/] = totalShares[watcher];
								
								UINTs[2]/*option count*/+=1;
							}
						}else if(ticket.rejected[watcher]){
							UINTs[1]/*weight of rejections*/ += totalShares[watcher];
						}
					}
				}else{
					ticket.damaged[watcher] = true;
				}
			}
			
			if( (UINTs[4]/*total Eligible Weight*/ == (UINTs[1]/*weight of rejections*/ + UINTs[0]/*weight of votes*/) && !ticket.subjective) || (_now() > ticket.timeRequested + ticket.timeWindow*(ticket.subjective?3:2) ) ){
				
				bool rejected;
				if( UINTs[1]/*weight of rejections*/ > optionWeights[UINTs[3]/*top option*/] || UINTs[2]/*option count*/ == 0){
					rejected = true;
				}
				uint8 dataType = ticket.dataType;
				//write results in stone
				if(rejected){
					ticket.ticketRejected = true;
				}else{				
					if(ticket.subjective){
						ticket.numberOfOptions = UINTs[2]/*option count*/;
						for(UINTs[6]=0;UINTs[6]<UINTs[2];UINTs[6]+=1){
							ticket.weightOfResults[UINTs[6]] = optionWeights[UINTs[6]];
							if(dataType == 1){
								ticket.resolvedInts[UINTs[6]] = intOptions[UINTs[6]];
							}else if(dataType == 0){
								ticket.resolvedAddresses[UINTs[6]] = addressOptions[UINTs[6]];
							}
						}
					}else{
						ticket.numberOfOptions = UINTs[2]==0?0:1;//just in case no one responds the number of options needs to be 0
						if(dataType == 1){
							ticket.resolvedInts[0] = intOptions[UINTs[3]/*top option*/];
						}else if(dataType == 0){
							ticket.resolvedAddresses[0] = addressOptions[UINTs[3]/*top option*/];
						}
					}
				}

				//dish out the rewards
				earningsPerShare[ORACLE] += ticket.serviceFee * scaleFactor / totalShares[ORACLE];

				ticket.finalized = true;
				if(ticket.subjective){
					if(dataType == 1){
						Requestor(ticket.sender).oracleIntFallback(ticket.ID, ticket.ticketRejected, ticket.numberOfOptions, optionWeights, intOptions);
					}else if(dataType == 0){
						Requestor(ticket.sender).oracleAddressFallback(ticket.ID, ticket.ticketRejected, ticket.numberOfOptions, optionWeights, addressOptions);
					}
				}else{
					if(dataType == 1){
						Requestor(ticket.sender).oracleObjectiveIntFallback(ticket.ID, ticket.ticketRejected, intOptions[0]);
					}else if(dataType == 0){
						Requestor(ticket.sender).oracleObjectiveAddressFallback(ticket.ID, ticket.ticketRejected, addressOptions[0]);
					}
				}
				
				emit FinalizedRequest(ticket.ID, watchers);
				lastTimeTicketWasFinalized = _now();
			}else{
				revert();
			}
		}
	}

	event Cashout(address addr, uint ETH);
	function cashout(address[] memory pools) external{
		address payable sender = payable(msg.sender);
		for(uint p; p < pools.length; p+=1){
			update(pools[p], sender);
		}
		runWatcherPayroll(sender);
		uint ETH = earnings[sender];
		earnings[sender] = 0;
		emit Cashout(sender, ETH);
		$MM.transfer(sender, ETH );
	}

	function runWatcherPayroll(address watcher) public{
		if( isWatcher[watcher] ){
			update(ORACLE, watcher );
			updateWatcherTxEarnings( watcher, true );
		}
	}

	function tryToPunish(uint[] memory tickets, address[] memory watchers) external{
		freezeNoncommits(tickets, watchers);
		freezeUnrevealedCommits(tickets, watchers);
		freezeWrongWatchers(tickets, watchers);
	}

	event FreezeNoncommits(uint ticketID, address watcher);
	function freezeNoncommits(uint[] memory tickets, address[] memory watchers) public{
		// get them while they're still at the round table and we're in the reveal phase of a ticket
		RequestTicket storage ticket;
		for(uint i; i<watchers.length; i+=1){
			ticket = requestTickets[ tickets[i] ];
			if( isWatcher[ watchers[i] ] &&
				!ticket.committed[ watchers[i] ] &&
				timeSeated[ watchers[i] ] <= ticket.timeRequested &&
				_now() > ticket.timeRequested + ticket.timeWindow
			){
				if(punish(tickets[i] , watchers[i]) ){
					emit FreezeNoncommits(tickets[i] , watchers[i]);
				}
			}
		}
	}
	
	event FreezeUnrevealedCommits(uint ticketID, address watcher);
	function freezeUnrevealedCommits(uint[] memory tickets, address[] memory watchers) public{
		// get them if they made a commit, but did not reveal it after the reveal window is over
		RequestTicket storage ticket;
		for(uint i; i<watchers.length; i+=1){
		    ticket = requestTickets[ tickets[i] ];
			if( isWatcher[ watchers[i] ] &&
				!ticket.revealed[ watchers[i] ] &&
				timeSeated[ watchers[i] ] <= ticket.timeRequested &&
				_now() > requestTickets[ tickets[i] ].timeRequested + ticket.timeWindow*2
			){
				if(punish(tickets[i] , watchers[i]) ){
					emit FreezeUnrevealedCommits(tickets[i] , watchers[i]);
				}
			}
		}
	}

	event FreezeWrongWatchers(uint ticketID, address watcher);
	function freezeWrongWatchers(uint[] memory tickets, address[] memory watchers) public{
		// get them if the ticket is finalized and their vote doesn't match the resolved answer
		address watcher;
		RequestTicket storage ticket;
		for(uint i; i<watchers.length; i+=1){
			ticket = requestTickets[ tickets[i] ];
			watcher = watchers[i];
			if( ticket.finalized &&
				isWatcher[ watchers[i] ] &&
				timeSeated[ watchers[i] ] <= ticket.timeRequested &&
				!ticket.ticketRejected &&
				(
					(!ticket.subjective && (
						(ticket.dataType == 1 && ticket.resolvedInts[0] != ticket.intVotes[ watcher ] )||
						(ticket.dataType == 0 && ticket.resolvedAddresses[0] != ticket.addressVotes[ watcher ] )
					))||
					(ticket.subjective && ticket.damaged[ watcher ] )||//if their subjective contribution is garbage
					ticket.rejected[ watcher ]//if they reject something the majority didn't reject
				)
			){
				if(punish(tickets[i] , watcher)){
					emit FreezeWrongWatchers(tickets[i] , watcher);
				}
			}
		}
	}

	event Punish(address watcher, uint thawOutTime);
	function punish(uint ticketID, address watcher) internal returns(bool punished){
		RequestTicket storage ticket = requestTickets[ticketID];
		if(latestPunishment[watcher] < ticket.timeRequested+ticket.timeWindow*(ticket.subjective?3:2)){
			if( isWatcher[watcher] ){
				removeShares(ORACLE, watcher, totalShares[watcher]);
			}

			frozen[watcher] = true;
			latestPunishment[watcher] = ticket.timeRequested;
			timeWhenThawedOut[watcher] = _now() + oracleConfigurations[FREEZE_TIMEOUT];

			emit Punish(watcher, timeWhenThawedOut[watcher]);
			return true;
		}
		return false;
	}

	event Thaw(address candidate);
	function thaw(address candidate, bool _assert) public{
		if( _now() >= timeWhenThawedOut[candidate] && frozen[candidate] ) {
			frozen[candidate] = false;
			if(_assert && candidate == msg.sender){
				assertCandidate();
			}
			emit Thaw(candidate);
		}else{
			revert();
		}
	}

	event UpdateRoundTable(uint newTotalHotSeats);
	function updateRoundTable(uint seats) public{
		// update hotSeats for when they're lower.
		uint s;
		uint i;
		uint weakestChair;
		address thisWatcher;
		uint configSEATS = oracleConfigurations[ROUNDTABLE_SEATS];

		if( configSEATS == hotSeats ) return;

		if( hotSeats > totalWatchers && configSEATS < hotSeats){
			hotSeats = totalWatchers;
		}

		for( s = 0; s<seats; s+=1 ){

			for( i=0; i<hotSeats; i+=1){
				thisWatcher = chairsCandidate[i];
				if( totalShares[ thisWatcher ] < totalShares[ chairsCandidate[weakestChair] ] ){
					weakestChair = i;
				}
			}

			thisWatcher = chairsCandidate[weakestChair];
			removeShares(ORACLE, thisWatcher, totalShares[thisWatcher]);

			hotSeats-=1;

			if( configSEATS == hotSeats ){break;}
		}

		emit UpdateRoundTable(hotSeats);
	}

	function viewRequestTicket(uint ticketID) public view returns(
		address sender,
		uint timeRequested,
		uint timeWindow,
		uint numberOfOptions,
		bool finalized,
		bool rejected,
		uint[] memory weightOfResults,
		int[] memory resolvedInts,
		address[] memory resolvedAddresses
	){	
		RequestTicket storage T = requestTickets[ticketID];
		sender = T.sender;
		timeRequested = T.timeRequested;
		timeWindow = T.timeWindow;
		finalized = T.finalized;
		numberOfOptions = T.numberOfOptions;
		rejected = T.ticketRejected;

		weightOfResults = new uint[](T.numberOfOptions);
		resolvedInts = new int[](T.numberOfOptions);
		resolvedAddresses = new address[](T.numberOfOptions);
		//yikes
		for(uint i = 0; i< T.numberOfOptions; i+=1){
			weightOfResults[i] = T.weightOfResults[i];
			resolvedInts[i] = T.resolvedInts[i];
			resolvedAddresses[i] = T.resolvedAddresses[i];	
		}
	}

	function viewCandidates(bool personal_or_roundtable, address perspective) public view returns(address[] memory addresses, uint[] memory dividends, uint[] memory seat, uint[] memory weights, uint[] memory clocks, bool[] memory isFrozen, bool[] memory atTable, uint[] memory roundTableDividends){
		uint L;
		
		if(personal_or_roundtable){
			L = hotSeats;
		}else{
			L = yourBacking[perspective].length;
		}

		dividends = new uint[](L);
		seat = new uint[](L);
		roundTableDividends = new uint[](L);

		weights = new uint[](L*2);
		clocks = new uint[](L*3);

		isFrozen = new bool[](L);
		atTable = new bool[](L);

		addresses = new address[](L);

		address candidate;
		for(uint c = 0; c<L; c+=1){
			if(personal_or_roundtable){
				candidate = chairsCandidate[c];
			}else{
				candidate = yourBacking[perspective][c];
			}
			addresses[c] = candidate;
			dividends[c] = dividendsOf(candidate, perspective);
			roundTableDividends[c] = dividendsOf(ORACLE, candidate);
			seat[c] = candidatesChair[candidate];
			weights[c] = shares[candidate][perspective];
			weights[c+L] = totalShares[candidate];
			isFrozen[c] = frozen[candidate];
			atTable[c] = isWatcher[candidate];
			clocks[c] = timeWhenThawedOut[candidate];
			clocks[c+L] = timeSeated[candidate];
			clocks[c+L*2] = latestPunishment[candidate];
		}
	}

	function viewGovernance() public view returns(uint[] memory data){
		data = new uint[](CONFIGS);
		for(uint i = 0; i< CONFIGS; i+=1){
			data[i] = oracleConfigurations[i];
		}
	}
	
	function accountData(address account) public view returns(
		uint _resolveWeight,
		uint _weightLocked,
		uint _timeSeated,
		bool _frozen,
		bool _isWatcher,
		uint _earnings,
		uint _totalShares,
		uint[] memory UINTs
	){
		_resolveWeight = resolveWeight[account];
		_weightLocked = weightLocked[account];
		_timeSeated = timeSeated[account];
		_frozen = frozen[account];
		_isWatcher = isWatcher[account];
		_earnings = earnings[account];
		_totalShares = totalShares[account];
		UINTs = new uint[](5);

		if( _isWatcher ){
			UINTs[0] = earningsPerWatcher - watcherPayouts[account];//txCoverageFee
			UINTs[1] = dividendsOf(ORACLE, account) * oracleConfigurations[DELEGATE_REWARDSHARE] / (1e20);
		}

		UINTs[2] = timeWhenThawedOut[account];
		UINTs[3] = latestPunishment[account];
		UINTs[4] = candidatesChair[account];
	}

	function compareStrings(string memory a, string memory b) public pure returns (bool) {
		return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))) );
	}
	function compareBytes(bytes32 a, bytes32 b) public pure returns (bool) {
		return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))) );
	}
	function bytesToAddress(bytes memory bys) private pure returns (address addr){
        assembly {
          addr := mload( add(bys,20) )
        } 
    }
}

abstract contract ERC20{
	function transfer(address _to, uint _value) public virtual returns (bool);
    function transferFrom(address src, address dst, uint amount) public virtual returns (bool);
}

abstract contract ResolveToken{
	function transfer(address _to, uint256 _value) public virtual returns (bool);
}

abstract contract Pyramid{
	function resolveToken() public view virtual returns(ResolveToken);
}

abstract contract Requestor{
	function oracleIntFallback(uint ticketID, bool EXCEPTION, uint numberOfOptions, uint[] memory optionWeights, int[] memory intOptions) public virtual;
	function oracleAddressFallback(uint ticketID, bool EXCEPTION, uint numberOfOptions, uint[] memory optionWeights, address[] memory addressOptions) external virtual;
	function oracleObjectiveIntFallback(uint ticketID, bool EXCEPTION, int resolved_int) external virtual;
	function oracleObjectiveAddressFallback(uint ticketID, bool EXCEPTION, address resolved_address) external virtual;
}