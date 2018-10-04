#!/usr/bin/python3

import os
import sys
import grpc

import ep11, grep11_pb2, pkcs11_pb2, server_pb2, server_pb2_grpc, grep11_pb2_grpc 
#from .pyep11 import pkcs11_pb2
#from .pyep11 import keystore_pb2
#from .pyep11 import grep11_pb2_grpc
import sqlite3
import binascii

endian = 'big'

class AES:

    def __init__(self, key):
        print("pyep11.AES: key=" + key.hex())
        if len(key) not in (16, 24, 32):
            raise ValueError('Invalid key size')
        # self.grep11ServerStub = 0
        self.ep11init()
        
    def ep11init(self):
        if not os.environ.get('ZHSM'):
            print("$ZHSM environment variable is not set, defaulting to the original software AES")
            self.grep11ServerStub = 0
        else:
            zhsm = os.environ['ZHSM']
            print("zHSM host: " + zhsm)
            channel = grpc.insecure_channel(zhsm + ':9876')
            self.grep11ServerStub = server_pb2_grpc.CryptoStub(channel)
 
    def ep11enabled(self):
        if self.grep11ServerStub == 0:
            return False
        else:
            return True

    def dbopen(self):
        self.connection = sqlite3.connect('/data/electrum/keystore.sqlite')
        self.cursor = self.connection.cursor()
        try:
            # CREATE
            self.cursor.execute(
                "CREATE TABLE IF NOT EXISTS keystore (key TEXT PRIMARY KEY, ep11key BLOB)")
        except sqlite3.Error as e:
            print('sqlite3.Error occurred:', e.args[0])
 
    def dbclose(self):
        self.connection.commit()
        self.connection.close()

    def ep11key(self, key):
        self.dbopen()
        try:
            self.cursor.execute("SELECT ep11key FROM keystore WHERE key=?", (key,))
            result = self.cursor.fetchall()
            # print(result)
            if len(result) == 0:
                r = server_pb2.GenerateKeyRequest(Mech=pkcs11_pb2.Mechanism(Mechanism=ep11.CKM_AES_KEY_GEN))
                r.Template[ep11.CKA_VALUE_LEN] = (16).to_bytes(8,byteorder=endian)
                r.Template[ep11.CKA_WRAP] = (0).to_bytes(1,byteorder=endian)
                r.Template[ep11.CKA_UNWRAP] = (0).to_bytes(1,byteorder=endian)
                r.Template[ep11.CKA_ENCRYPT] = (1).to_bytes(1,byteorder=endian)
                r.Template[ep11.CKA_DECRYPT] = (1).to_bytes(1,byteorder=endian)
                r.Template[ep11.CKA_EXTRACTABLE] = (0).to_bytes(1,byteorder=endian)
                r.Template[ep11.CKA_TOKEN] = (1).to_bytes(1,byteorder=endian)
                generateKeyStatus = self.grep11ServerStub.GenerateKey(r)
                ep11key = generateKeyStatus.Key
                encoded = str(binascii.hexlify(ep11key))
                print("ep11key generated key=" + key.hex() + " ep11key=" + ep11key.hex())
                # INSERT
                self.cursor.execute("INSERT INTO keystore VALUES (:key, :ep11key)",
                                    {'key': key, 'ep11key':ep11key})
            elif len(result) == 1:
                # ep11key = int(result[0][0], 16)
                ep11key = result[0][0]
                # ep11key = binascii.unhexlify(bytes(encoded))
                print("ep11key found key=" + key.hex() + " ep11key=" + ep11key.hex())
            else:
                print("ep11key found multiple keys unexpectedly\n")
                sys.exit(-1)
            
        except sqlite3.Error as e:
            print('sqlite3.Error occurred:', e.args[0])

        self.dbclose()
        return ep11key # cls.keyStore[key]
   
    def encrypt_with_iv(self, key, iv, data):
        if self.grep11ServerStub == 0:
            return None # no ZHSM, defaulting to the software AES
        ep11key = self.ep11key(key)
        print("pyep11.AES.encrypt: key=" + key.hex())

        cipherInitInfo = server_pb2.EncryptInitRequest(Mech=pkcs11_pb2.Mechanism(Mechanism=ep11.CKM_AES_CBC_PAD,
                                                                                 Parameter=iv),
                                                       Key = ep11key)
        cipherState = self.grep11ServerStub.EncryptInit(cipherInitInfo)
        # print("cipherState.StateOut: " + cipherState.StateOut.hex())
        # print("cipherState.DataOut: " + cipherState.DataOut.hex())

        cipherData = server_pb2.EncryptUpdateRequest(State=cipherState.State,
                                                     Plain=data)
        # print("total size: " + str(len(plain[:].decode())))
        # print("first size: " + str(len(cipherData.DataIn.decode())) + " " + cipherData.DataIn.decode())
        cipherState = self.grep11ServerStub.EncryptUpdate(cipherData)
        # print("cipherState.StateOut: " + cipherState.StateOut.hex())
        # print("cipherState.DataOut: " + cipherState.DataOut.hex())

        ciphertext = cipherState.Ciphered[:]
        cipherData.State = cipherState.State
        cipherData.Plain = b''
        # print("third size: " + str(len(cipherData.DataIn.decode())) + " " + cipherData.DataIn.decode())
        cipherState = self.grep11ServerStub.EncryptFinal(cipherData)
        # print("cipherState.StateOut: " + cipherState.StateOut.hex())
        # print("cipherState.DataOut: " + cipherState.DataOut.hex())

        ciphertext = ciphertext + cipherState.Ciphered[:]
        print("Original message  " + data.hex())
        print("Encrypted message " + ciphertext.hex())
        return ciphertext

    def decrypt_with_iv(self, key, iv, encrypted_data):
        if self.grep11ServerStub == 0:
            return None # no ZHSM, defaulting to the software AES
        ep11key = self.ep11key(key)
        print("pyep11.AES.decrypt: key=" + key.hex())

        cipherInitInfo = server_pb2.DecryptInitRequest(Mech=pkcs11_pb2.Mechanism(Mechanism=ep11.CKM_AES_CBC_PAD,
                                                                                 Parameter=iv),
                                                       Key = ep11key)
        cipherState = self.grep11ServerStub.DecryptInit(cipherInitInfo)

        cipherData = server_pb2.DecryptUpdateRequest(State=cipherState.State,
                                                     Ciphered=encrypted_data)

        cipherState = self.grep11ServerStub.DecryptUpdate(cipherData)

        plaintext = cipherState.Plain[:]

        cipherData.State = cipherState.State
        cipherData.Ciphered = b''
        cipherState = self.grep11ServerStub.DecryptFinal(cipherData)

        plaintext = plaintext + cipherState.Plain[:]
        print("Decrypted message  " + plaintext.hex())
        print("Encrypted message  " + encrypted_data.hex())

        return plaintext


#def run():

            
#    generateRandomInfo = server_pb2.GenerateRandomInfo(Len = ep11.AES_BLOCK_SIZE)
#    generateRandomStatus = stub.GenerateRandom(generateRandomInfo)
#    print("generateRandomStatus.Rnd:" + generateRandomStatus.Rnd.hex())

#    iv = generateRandomStatus.Rnd[:ep11.AES_BLOCK_SIZE]
#    print("iv: " + iv.hex())
#    plain = "Hello, this is a very long and creative message without any imagination".encode()


# if __name__ == '__main__':
#    run()


