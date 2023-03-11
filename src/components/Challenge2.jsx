import React from 'react';
import challengeCode from '../assets/challenge2.cairo'
import '../App.css';
import { useAccount,useConnectors,useStarknetExecute,useTransactionReceipt,
        useStarknetCall,useContract } from '@starknet-react/core';
import { useState } from 'react' 

import { StarknetConfig, InjectedConnector } from '@starknet-react/core'
import mainABI from '../assets/main_abi.json'
import global from '../global.jsx'

import { monokaiSublime } from 'react-syntax-highlighter/dist/esm/styles/hljs';
import SyntaxHighlighter from 'react-syntax-highlighter';

import ToggleSwitch from './ToggleSwitch.js';

const connectors = [
  new InjectedConnector({ options: { id: 'braavos' }}),
  new InjectedConnector({ options: { id: 'argentX' }}),
]

function Points(){
        const { contract } = useContract({
        address: global.MAIN_CONTRACT_ADDRESS,
        abi: mainABI
        })
        const { address } = useAccount()
        const { data , loading, error, refresh } = useStarknetCall({
            contract,
            method: 'get_points',
            args:[address],
            options: {
                watch: true
            }
        })
    
        if (loading) return <span>Loading...</span>
        if (error) return <span>Error: {error}</span>
        return(
            <span>
            Your Score:{data[0].toString()}
            </span>
        ) 
}

function Status(){
    const { contract } = useContract({
    address: global.MAIN_CONTRACT_ADDRESS,
    abi: mainABI
    })
    const { address } = useAccount()
    const { data , loading, error, refresh } = useStarknetCall({
        contract,
        method: 'get_challenge_status',
        args:[address,'2'],
        options: {
            watch: true
        }
    })

    if (loading) return <span>Loading...</span>
    if (error) return <span>Error: {error}</span>
    return(
        <span>
        {data && !parseInt(data[0].toString())?<Challenge2Deploy />:<span>Already Resolved</span>}
        </span>
    ) 
}

function ConnectWallet() {
  const { connect, connectors } = useConnectors()
  const { address } = useAccount()
  const { disconnect } = useConnectors()

  if (!address) 
  return (
    <div>
      {connectors.map((connector) => (
        <p key={connector.id()}>
          <button onClick={() => connect(connector)}>
            Connect {connector.id()}
          </button>
        </p>
      ))}
    </div>
  )
  return (
    <>
      <p>Connected: {address.substring(0,6)}...{address.substring(address.length - 4)}.</p>
      {address && <p><Points /></p>}
      {address && <p><Status /></p>}
    </>
  )
}

function Challenge2Deploy() {

    const [hash, setHash] = useState(undefined)
    const { data, loading, error } = useTransactionReceipt({ hash, watch: true })

    const { execute } = useStarknetExecute({
      calls: [{
        contractAddress: global.MAIN_CONTRACT_ADDRESS,
        entrypoint: 'deploy_challenge',
        calldata: ['2']
      }]
    })
  
    const handleClick = () => {
      execute().then(tx => setHash(tx.transaction_hash))
    }

    let newContractAddress=""
    if (data)
    if ((data.status=="ACCEPTED_ON_L2")||data.status=="ACCEPTED_ON_L1")
      data.events.forEach(event => {
        let paddedFrom="0x"+event.from_address.substring(2).padStart(64,'0')
        if (paddedFrom==global.MAIN_CONTRACT_ADDRESS)
          newContractAddress=event.data[0]
      })

    return (
      <>
        <p><button onClick={handleClick}>Begin Challenge</button></p>
        {error && <div>Error: {JSON.stringify(error)}</div>}
        {data && <div><div>Tx.Hash: {hash}</div> <div>Status: {data.status}  </div></div>}      
        {data && (data.status=="ACCEPTED_ON_L2"||data.status=="ACCEPTED_ON_L1") && <div> Challenge contract deployed at address: {newContractAddress} </div>}
        {data && (data.status=="ACCEPTED_ON_L2"||data.status=="ACCEPTED_ON_L1") && data.events?<div> <Challenge2Check /> </div>:<div></div>}
       </>
    )
}

function Challenge2Check() {
    const [hash, setHash] = useState(undefined)
    const { data, loading, error } = useTransactionReceipt({ hash, watch: true })

    const { execute } = useStarknetExecute({
      calls: [{
        contractAddress: global.MAIN_CONTRACT_ADDRESS,
        entrypoint: 'test_challenge',
        calldata: ['2']
      }]
    })
  
    const handleClick = () => {
      execute().then(tx => setHash(tx.transaction_hash))
    }

    return (
      <>
        <p><button onClick={handleClick}>Check Solution</button></p>
        {error && <div>Error: {JSON.stringify(error)}</div>}
        {data && <div><div>Tx.Hash: {hash}</div> <div>Status: {data.status}  </div></div>}      
       </>
    )
  }

function Challenge2() {
  const [text, setText] = React.useState();
  fetch(challengeCode)
    .then((response) => response.text())
    .then((textContent) => {
      setText(textContent);
    });
    const textOptions = ["EN", "ES"];
    const chkID = "checkboxID";
    const [lang, setLang] = useState(true);

    if (lang) {
return (
    <div className="App" class='flex-table row' role='rowgroup'>
      <div class='flex-row-emp' role='cell'></div>
      
      <div class='flex-row-wide' role='cell'>
      <div align='center'>
      <ToggleSwitch id={chkID} checked={lang} optionLabels={textOptions} small={true} onChange={checked => setLang(checked)} />
      </div>
        <StarknetConfig connectors={connectors}>
          <p><font size="+2"><b>CALL ME</b></font></p>
          To complete this challenge, all you need to do is call a function.<br /><br />
          The “Begin Challenge” button will deploy the following contract, call the function named 
          callme and then click the “Check Solution” button.<br /><br />
          Here’s the code for this challenge:
          <div align='justify'>
            <SyntaxHighlighter language="cpp" style={monokaiSublime} customStyle={{backgroundColor: "#000000",fontSize:12}} smart-tabs='true' showLineNumbers="true">
              {text}
            </SyntaxHighlighter>
          </div>
          <ConnectWallet />
        </StarknetConfig>
      </div>
        
      <div class='flex-row-emp' role='cell'></div>
    </div>
  );
}else{
  return (
    <div className="App" class='flex-table row' role='rowgroup'>
      <div class='flex-row-emp' role='cell'></div>
      
      <div class='flex-row-wide' role='cell'>
      <div align='center'>
      <ToggleSwitch id={chkID} checked={lang} optionLabels={textOptions} small={true} onChange={checked => setLang(checked)} />
      </div>
        <StarknetConfig connectors={connectors}>
          <p><font size="+2"><b>CALL ME</b></font></p>
          Para completar este desafío, todo lo que necesita hacer es llamar a una función.<br /><br />
           El botón "Begin Challenge" desplegará el siguiente contrato, llama a la función denominada
           callme y luego haz clic en el botón "Check Solution".<br /><br />
           Aquí está el código para este desafío:
          <div align='justify'>
            <SyntaxHighlighter language="cpp" style={monokaiSublime} customStyle={{backgroundColor: "#000000",fontSize:12}} smart-tabs='true' showLineNumbers="true">
              {text}
            </SyntaxHighlighter>
          </div>
          <ConnectWallet />
        </StarknetConfig>
      </div>
        
      <div class='flex-row-emp' role='cell'></div>
    </div>
  );
}
}

export default Challenge2;