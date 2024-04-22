import { getFullnodeUrl, SuiClient } from '@mysten/sui.js/client';
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import dotenv from 'dotenv';
import * as fs from 'fs';

dotenv.config();

export interface IObjectInfo {
  type: string | undefined;
  id: string | undefined;
}

export const keypair = Ed25519Keypair.fromSecretKey(Uint8Array.from(Buffer.from(process.env.KEY!, 'base64')).slice(1));

export const client = new SuiClient({ url: getFullnodeUrl('testnet') });

export const createCoinDecimals = (txb: TransactionBlock) => {
  const coinDecimals = txb.moveCall({
    target: `${process.env.SUI_TEARS!}::coin_decimals::new`,
  });

  txb.moveCall({
    target: '0x2::transfer::public_share_object',
    typeArguments: [`${process.env.SUI_TEARS!}::coin_decimals::CoinDecimals`],
    arguments: [coinDecimals],
  });

  return txb;
};

export const getId = (type: string): string | undefined => {
  try {
    const rawData = fs.readFileSync('../clamm.json', 'utf8');
    const parsedData: IObjectInfo[] = JSON.parse(rawData);
    const typeToId = new Map(parsedData.map((item) => [item.type, item.id]));
    return typeToId.get(type);
  } catch (error) {
    console.error('Error reading the CLAMM file:', error);
  }
};
