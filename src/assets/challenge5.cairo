%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.starknet.common.syscalls import get_contract_address,get_caller_address
from starkware.cairo.common.uint256 import (Uint256,uint256_eq)
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.hash import hash2

@contract_interface
namespace IERC20 {
    func balanceOf(account: felt) -> (balance: Uint256) {
    }
    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }
}

@storage_var
func is_complete() -> (value: felt) {
}

const hash_result=0x23c16a2a9adbcd4988f04bbc6bc6d90275cfc5a03fbe28a6a9a3070429acb96;

// ######## Constructor

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}() {
    alloc_locals;
    is_complete.write(FALSE);
    return ();
}

@view
func isComplete{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (output:felt) {
    alloc_locals;
    let (output)=is_complete.read();
    return (output=output);
}

@external
func guess{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    n:felt) {
    alloc_locals;
    let l2_token_address=0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

    let (contract_address)=get_contract_address();
    let (balance)=IERC20.balanceOf(contract_address=l2_token_address,account=contract_address); 

    let amount: Uint256 = Uint256(10000000000000000, 0);
    let (is_equal) = uint256_eq(balance, amount);
    with_attr error_message("Deposit required.") {
        assert is_equal = 1;
    }

    let field1 = 1000;
    let (res) = hash2{hash_ptr=pedersen_ptr}(field1, n);

    with_attr error_message("Incorrect guessed number.") {
        assert res=hash_result;
    } 
    
    let (sender)=get_caller_address();
    IERC20.transfer(contract_address=l2_token_address,recipient=sender,amount=amount);
    is_complete.write(TRUE);
    return();
}