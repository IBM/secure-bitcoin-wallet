#!/usr/bin/python3
##############################################################################
# Copyright 2020 IBM Corp. All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
##############################################################################

import os, sys, json, grpc, sqlite3, binascii, time
import grep11consts as ep11, grep11_pb2, pkcs11_pb2, server_pb2, server_pb2_grpc, grep11_pb2_grpc 
from subprocess import check_output

endian = 'big'

class AES:

    def __init__(self):
        self.zhsm = os.environ.get('ZHSM')
        self.apikey = os.environ.get('APIKEY')
        self.endpoint = os.environ.get('IAM_ENDPOINT', 'https://iam.cloud.ibm.com')
        self.channel = self.get_channel()

    class AuthPlugin(grpc.AuthMetadataPlugin):
        
        def __init__(self, apikey, endpoint):
            self._apikey = apikey
            self._endpoint = endpoint
            self._access_token = ''
            self._expiration = int(time.time())
            print('initial expiration=' + str(self._expiration))
    
        def __call__(self, context, callback):
            print('__call__ context=' + str(context))
            current = int(time.time())
            expiration = int(self._expiration) - 60 # set the expiration 60 sec before the actual one
            print('remaining=' + str(expiration - current) + ' expiration=' + str(expiration) + ' current=' + str(current))
            if expiration < current:
                print('renewing an access token')
                self.get_access_token()
                valid_for = int(self._expiration) - int(time.time())
                print('new expiration=' + str(self._expiration) + ' valid for ' + str(valid_for) + ' sec')
            metadata = (('authorization', 'Bearer {}'.format(self._access_token)),)
            #print('metadata=' + str(metadata))
            callback(metadata, None)

        def get_access_token(self):
            print("*** get a new access token for an HPCS instance on IBM Cloud ***")
        
            # print("APIKEY=" + self._apikey)
            print("ENDPOINT=" + self._endpoint)
    
            cmd = 'curl -sS -k -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" --data-urlencode "apikey=' + self._apikey + '" "' + self._endpoint + '/identity/token"'

            try:
                resp_str = check_output(cmd, shell=True).rstrip().decode('utf8')
            except Exception as e:
                print('an unexpected response from IAM_ENDPOINT=' + self._endpoint)
                print(e)
                import traceback
                traceback.print_exc()
                return None

            try:
                resp = json.loads(resp_str)
                # print('response=' + json.dumps(resp, indent=4))
                self._expiration = resp['expiration']
                self._access_token = resp['access_token']
                print('access_token=' + 'xxxxxxxxxxxxxxxxxxxxxxxxx...')
                return self._access_token
        
            except Exception as e:
                print('an unexpected response from IAM_ENDPOINT=' + self._endpoint)
                print('response=' + str(resp_str))
                print(e)
                import traceback
                traceback.print_exc()
                return None

    def get_channel(self):
        if not self.zhsm:
            channel = None
            print("using a software crypto")
        elif not self.apikey:
            print("accessing an on-prem HPCS (grep11) at "  + self.zhsm + " - $APIKEY environment variable is not set")
            channel = grpc.insecure_channel(self.zhsm)
        else:
            print("accessing an HPCS instance on IBM Cloud at " + self.zhsm)
            print("ZHSM=" + self.zhsm)
            # print("APIKEY=" + self.apikey)
            print("ENDPOINT=" + self.endpoint)

            call_credentials = grpc.metadata_call_credentials(self.AuthPlugin(self.apikey, self.endpoint))
            channel_credential = grpc.ssl_channel_credentials()
            composite_credentials = grpc.composite_channel_credentials(channel_credential, call_credentials)
            channel = grpc.secure_channel(self.zhsm, composite_credentials)

        return channel

    def dbopen(self):
        self.connection = sqlite3.connect('/data/electrum/keystore.sqlite')
        self.cursor = self.connection.cursor()
        try:
            # CREATE
            self.cursor.execute(
                "CREATE TABLE IF NOT EXISTS keystore (key TEXT PRIMARY KEY, ep11key BLOB)")
        except sqlite3.Error as e:
            print('sqlite3.Error occurred:', e.args[0])
            sys.exit(-1)

    def dbclose(self):
        self.connection.commit()
        self.connection.close()

    def ep11key(self, grep11ServerStub,  key):
        print("pyep11.ep11key: key=" + key.hex())
        if len(key) not in (16, 24, 32):
            raise ValueError('Invalid key size')

        self.dbopen()
        try:
            self.cursor.execute("SELECT ep11key FROM keystore WHERE key=?", (key,))
            result = self.cursor.fetchall()
            if len(result) == 0:
                r = server_pb2.GenerateKeyRequest(Mech=pkcs11_pb2.Mechanism(Mechanism=ep11.CKM_AES_KEY_GEN))
                r.Template[ep11.CKA_VALUE_LEN] = (16).to_bytes(8,byteorder=endian)
                r.Template[ep11.CKA_WRAP] = (0).to_bytes(1,byteorder=endian)
                r.Template[ep11.CKA_UNWRAP] = (0).to_bytes(1,byteorder=endian)
                r.Template[ep11.CKA_ENCRYPT] = (1).to_bytes(1,byteorder=endian)
                r.Template[ep11.CKA_DECRYPT] = (1).to_bytes(1,byteorder=endian)
                r.Template[ep11.CKA_EXTRACTABLE] = (0).to_bytes(1,byteorder=endian)
                r.Template[ep11.CKA_TOKEN] = (1).to_bytes(1,byteorder=endian)
                generateKeyStatus = grep11ServerStub.GenerateKey(r)
                ep11key = generateKeyStatus.Key
                encoded = str(binascii.hexlify(ep11key))
                print("ep11key generated key=" + key.hex() + " ep11key=" + ep11key.hex())
                # INSERT
                self.cursor.execute("INSERT INTO keystore VALUES (:key, :ep11key)",
                                    {'key': key, 'ep11key':ep11key})
            elif len(result) == 1:
                ep11key = result[0][0]
                print("ep11key found key=" + key.hex() + " ep11key=" + ep11key.hex())
            else:
                print("ep11key found multiple keys unexpectedly\n")
                sys.exit(-1)
            
        except sqlite3.Error as e:
            print('sqlite3.Error occurred:', e.args[0])
            sys.exit(-1)

        self.dbclose()
        return ep11key
   
    def encrypt_with_iv(self, key, iv, data):
        # return None if there is no ZHSM
        if not self.channel:
            return None
        
        grep11ServerStub = server_pb2_grpc.CryptoStub(self.channel)
        
        try:
            ep11key = self.ep11key(grep11ServerStub, key)
            print("pyep11.AES.encrypt: key=" + key.hex())
            
            request = server_pb2.EncryptSingleRequest(Mech=pkcs11_pb2.Mechanism(Mechanism=ep11.CKM_AES_CBC_PAD,
                                                                                Parameter=iv),
                                                      Key = ep11key,
                                                      Plain=data)
            cipherState = grep11ServerStub.EncryptSingle(request)
            
            ciphertext = cipherState.Ciphered[:]
            if len(data) < 128:
                print("Original message  " + str(data))
            else:
                print("Original message  " + "..........................")
            #print("Original message  " + data.hex())
            #print("Encrypted message " + ciphertext.hex())

            return ciphertext

        except grpc.RpcError as rpc_error:
            print(f'encrypt_with_iv: RPC failed with code {rpc_error.code()}: {rpc_error}')
            print('grpc error code=' + str(rpc_error._state.code) + ' ' + str(type(rpc_error._state.code)))
            return None
    
        except Exception as e:
            exc_type, exc_obj, tb = sys.exc_info()
            lineno = tb.tb_lineno
            print('Unexpected error: ' + str(e) + ' ' + str(type(e)) + ' at ' + str(lineno))
            return None
    
    def decrypt_with_iv(self, key, iv, encrypted_data):
        # return None if there is no ZHSM
        if not self.channel:
            return None
        
        grep11ServerStub = server_pb2_grpc.CryptoStub(self.channel)
        
        try:
            ep11key = self.ep11key(grep11ServerStub, key)
            print("pyep11.AES.decrypt: key=" + key.hex())

            request = server_pb2.DecryptSingleRequest(Mech=pkcs11_pb2.Mechanism(Mechanism=ep11.CKM_AES_CBC_PAD,
                                                                                Parameter=iv),
                                                      Key = ep11key,
                                                      Ciphered=encrypted_data)
            cipherState = grep11ServerStub.DecryptSingle(request)

            plaintext = cipherState.Plain[:]
            if len(plaintext) < 128:
                print("Decrypted message  " + str(plaintext))
            else:
                print("Decrypted message  " + "..........................")
            #print("Decrypted message  " + plaintext.hex())
            #print("Encrypted message  " + encrypted_data.hex())

            return plaintext

        except grpc.RpcError as rpc_error:
            print(f'decrypt_with_iv: RPC failed with code {rpc_error.code()}: {rpc_error}')
            print('grpc error code=' + str(rpc_error._state.code) + ' ' + str(type(rpc_error._state.code)))
            return None
    
        except Exception as e:
            exc_type, exc_obj, tb = sys.exc_info()
            lineno = tb.tb_lineno
            print('Unexpected error: ' + str(e) + ' ' + str(type(e)) + ' at ' + str(lineno))
            return None
    

