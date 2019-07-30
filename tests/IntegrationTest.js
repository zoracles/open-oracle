const path = require('path');
const Web3 = require('web3');
const compose = require('docker-compose');
const contract = require('eth-saddle/dist/contract');

const root = path.join(__dirname, '..');

describe.only('Integration', () => {
  it('deploys the contracts, starts reporters and posts the right prices', async () => {
    await compose.upAll({cwd: root, log: true});
    await new Promise(ok => setTimeout(ok, 3000));

    const web3 = new Web3('http://localhost:8545');
    // const accounts = await web3.eth.getAccounts();
    let delfi;
    await contract.getContractAt(web3, 'DelFiPrice', '0x5b1869D9A4C187F2EAa108f3062412ecf0526b24').then((d) => delfi = d);

    let account;
    await web3.eth.getAccounts().then((x) => accounts = x);

    // let n = await delfi.methods.numb().send({from: accounts[0]});
    let m = await delfi.methods.numb().call();
    // console.log(n)
    console.log(m)
    expect(m).numEquals(2);
    expect(await delfi.methods.prices('BTC').call({from: accounts[0]})).numEquals(0);
    expect(await delfi.methods.prices('ETH').call({from: accounts[0]})).numEquals('260000000');
    expect(await delfi.methods.prices('ZRX').call({from: accounts[0]})).numEquals('580000');

    await compose.down({cwd: root});
  }, 60000);
});
