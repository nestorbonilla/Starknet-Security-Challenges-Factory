// ######## Main
// When change this contract interface remember update ABI file at react project.

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.math_cmp import is_le
from starkware.starknet.common.syscalls import deploy,get_caller_address
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.upgrades.library import Proxy

// Interface to check challenge solution
@contract_interface
namespace ITestContract {
    func isComplete() -> (result:felt){
    }
}

// Interface to NFT
@contract_interface
namespace INFT {
    func mint(to: felt, tokenId: Uint256){
    }
    
    func setTokenURI(base_token_uri_len: felt, base_token_uri: felt*, token_uri_suffix: felt){
    }
}
// ######## Storage variables and structs

// Struct to storage players challenge status.
struct player_challenges_struct{
    address:felt,
    resolved:felt,
    minted:felt,
}

// Define a storage variable for players challenge status.
@storage_var
func player_challenges(player:felt,challenge_number:felt) -> (res: player_challenges_struct) {
}

// Struct for storage players info.
struct player_struct{
    id:felt,
    nickname:felt,
    points:felt,
    address:felt,
}

//Variable to query player data by address
@storage_var
func player(player_address:felt) -> (res:player_struct) {
}

//Variable to query player data by id (used for ranking)
@storage_var
func registered_players(player_id:felt) -> (res:player_struct) {
}

// Total players (players added when complete his first challenge)
@storage_var
func player_count() -> (res:felt) {
}

// Struct to storage challenge info.
struct challenge_struct{
    class_hash:felt,
    points:felt,
}

// Define a storage variable for the challenges info.
@storage_var
func challenges(challenge_number:felt) -> (res: challenge_struct) {
}

// Define a storage variable for the salt.
@storage_var
func salt() -> (value: felt) {
}

// Define a storage variable for the NFT Collection Address.
@storage_var
func nft_address() -> (value: felt) {
}

// ######## Events

// An event emitted whenever deploy challenges.
@event
func contract_deployed(contract_address: felt) {
}

@event
func e1(res: felt) {
}

@event
func e2(res: felt) {
}
// ######## External functions

// Function to deploy challenges to players
@external
func deploy_challenge{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _challenge_number: felt
    ) -> (new_contract_address:felt) {
    alloc_locals;
    let (sender) = get_caller_address();
    let (current_salt) = salt.read();
    let (current_challenge) = challenges.read(_challenge_number);
    let class_hash = current_challenge.class_hash;
    let (ctor_calldata) = alloc();

    let le : felt = is_le(_challenge_number, 4);

    if (le == 1){
       let (new_contract_address) = deploy(
            class_hash=class_hash,
            contract_address_salt=current_salt,
            constructor_calldata_size=0,
            constructor_calldata=ctor_calldata,
            //constructor_calldata=cast(new (sender,), felt*),
            deploy_from_zero=FALSE,
        );
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        let (new_contract_address) = deploy(
            class_hash=class_hash,
            contract_address_salt=current_salt,
            constructor_calldata_size=0,
            constructor_calldata=ctor_calldata,
            //constructor_calldata=cast(new (sender,), felt*),
            deploy_from_zero=FALSE,
        );
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }


    salt.write(value=current_salt + 1);

    contract_deployed.emit(
        contract_address=new_contract_address
    );

    //Assign challenge to player
    let new_challenge = player_challenges_struct(address=new_contract_address,resolved=FALSE,minted=FALSE);
    player_challenges.write(sender,_challenge_number,new_challenge);

    return (new_contract_address,);
}


// Function to test if challenge was completed by player
@external
func test_challenge{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _challenge_number: felt
    ) -> (_result:felt) {
    alloc_locals;
    let (sender) = get_caller_address();
    let (current_player_challenge) = player_challenges.read(sender,_challenge_number);

    //Check if is already resolved
    with_attr error_message("Challenge already resolved.") {
        assert_not_equal (current_player_challenge.resolved,TRUE);
    }

    //Check if resolved
    // if (_challenge_number == 1000){
    //     let (_result) = ITestContract.isComplete3(current_player_challenge.address,sender);
    //     tempvar syscall_ptr = syscall_ptr;
    //     tempvar pedersen_ptr = pedersen_ptr;
    //     tempvar range_check_ptr = range_check_ptr;
    // } else {
        let (_result) = ITestContract.isComplete(current_player_challenge.address);
        // tempvar syscall_ptr = syscall_ptr;
        // tempvar pedersen_ptr = pedersen_ptr;
        // tempvar range_check_ptr = range_check_ptr;
    // }
    with_attr error_message("Challenge not resolved.") {
        assert_not_equal (_result,FALSE);
    }

    //At this point we know challenge was completed sucessfully

    //Update player resolved challenges
    let new_challenge = player_challenges_struct(address=current_player_challenge.address,resolved=TRUE,minted=FALSE);
    player_challenges.write(sender,_challenge_number,new_challenge);
    
    let (current_player) = player.read(sender);
    let (current_challenge)=challenges.read(_challenge_number);
    let player_id = current_player.id;
    // First time, get a new player id to add player to ranking
    if (current_player.points==0){
        let (player_id) = player_count.read();
        let (new_count)=player_count.read();
        let new_count2=new_count+1;
        player_count.write(new_count2);
        tempvar player_id = player_id;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }else{
        tempvar player_id = player_id;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    
    //Update player points
    let player_points = current_player.points + current_challenge.points;
    player.write(sender,player_struct(id=player_id,nickname=current_player.nickname,points=player_points,address=sender));
    //Add to ranking (sort in frontend)
    registered_players.write(player_id,player_struct(id=player_id,nickname=current_player.nickname,points=player_points,address=sender));
    

    return (_result=_result,);
}

// Function to mint an NFT after resolve a challenge
@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _challenge_number: felt
    ) {
    alloc_locals;
    let (sender) = get_caller_address();
    let (current_player_challenge) = player_challenges.read(sender,_challenge_number);

    //Check if is already resolved
    with_attr error_message("Challenge not resolved yet.") {
        assert_not_equal (current_player_challenge.resolved,FALSE);
    }

    //Check if is already minted
    with_attr error_message("Challenge already minted.") {
        assert_not_equal (current_player_challenge.minted,TRUE);
    }

    // Mint NFT
    let _tokenId : Uint256 = Uint256(_challenge_number, 0);
    let nft : felt = nft_address.read();
    INFT.mint(contract_address=nft, //NFT proxy contract address
            to=sender,
            tokenId=_tokenId);

    //Update player minted challenges
    let new_challenge = player_challenges_struct(address=current_player_challenge.address,resolved=TRUE,minted=TRUE);
    player_challenges.write(sender,_challenge_number,new_challenge);

    return ();
}

// Get player total points
@view
func get_points{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _player: felt
    ) -> (_points:felt) {
    alloc_locals;
    let (current_player)=player.read(_player);
    return(_points=current_player.points,);
}

// Get if challenge is already completed by player
@view
func get_challenge_status{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _player: felt, _challenge_number: felt
    ) -> (_resolved:felt) {
    alloc_locals;
    let (current_challenge)=player_challenges.read(_player,_challenge_number);
    return(_resolved=current_challenge.resolved,);
}

// Get if challenge is already completed by player
@view
func get_mint_status{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _player: felt, _challenge_number: felt
    ) -> (_minted:felt) {
    alloc_locals;
    let (current_challenge)=player_challenges.read(_player,_challenge_number);
    return(_minted=current_challenge.minted,);
}

// Get player nickname
@view
func get_nickname{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _player: felt) -> (_nickname:felt) {
    alloc_locals;
    let (current_player)=player.read(_player);
    return(_nickname=current_player.nickname,);
}


//Set player nickname
@external
func set_nickname{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _nickname: felt
    ) -> () {
    let (sender) = get_caller_address();
    let (current_player) = player.read(sender);
    let player_points = current_player.points;
    //Check if already resolved
    with_attr error_message("You must finish a challenge before set nickname.") {
        assert_not_equal(player_points,0);
    }
    player.write(sender,player_struct(id=current_player.id,nickname=_nickname,points=player_points,address=current_player.address));
    registered_players.write(current_player.id,player_struct(id=current_player.id,nickname=_nickname,points=player_points,address=current_player.address));
    
    return ();
}


// Set ranking array (recursive)
func setPlayer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _player_array:player_struct*,
    i:felt,
    total:felt) -> (){
    alloc_locals;
    //Check if last element
    if (i==total){
        return();
    }
    
    let (current_player)=registered_players.read(i);
    assert _player_array[i]=current_player;
    setPlayer(_player_array,i+1,total);

    return();
}

// Get players ranking (not ordered)
 @view
 func get_ranking{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (_player_list_len:felt,_player_list:player_struct*) {
    alloc_locals;
    let (local player_array: player_struct*) = alloc();
    let (total) = player_count.read();
    setPlayer(player_array,0,total);
    return(_player_list_len=total,_player_list=player_array,);
 }

// ******************************************
// ******************************************
// SPDX-License-Identifier: MIT *************
// ******************************************
// ******************************************

//
// Initializer
//

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt
) {
    Proxy.initializer(proxy_admin);
    return ();
}

//
// Upgrades
//

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

//
// Getters
//

@view
func getImplementationHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    implementation: felt
) {
    return Proxy.get_implementation_hash();
}

@view
func getAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (admin: felt) {
    return Proxy.get_admin();
}

@view
func getPlayerCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (total: felt) {
    alloc_locals;
    let (cant)=player_count.read();
    return(total=cant,);
}


//
// Setters
//

@external
func setAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(new_admin: felt) {
    Proxy.assert_only_admin();
    Proxy._set_admin(new_admin);
    return ();
}

@external
func updateChallenge{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    challenge_id: felt,
    new_class_hash :felt,
    new_points:felt) {
    Proxy.assert_only_admin();
    let new_challenge = challenge_struct(class_hash=new_class_hash,points=new_points);
    challenges.write(challenge_id,new_challenge);
    return ();
}

@external
func setNFTAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(new_nft_address: felt) {
    Proxy.assert_only_admin();

    nft_address.write(new_nft_address);
    return ();
}
