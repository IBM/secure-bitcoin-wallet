#!/usr/bin/python3

import os, sys, json, grpc, sqlite3, binascii
import ep11, grep11_pb2, pkcs11_pb2, server_pb2, server_pb2_grpc, grep11_pb2_grpc 
from subprocess import check_output

endian = 'big'

class AES:

    def __init__(self):
        self.zhsm = os.environ.get('ZHSM')
        self.apikey = os.environ.get('APIKEY')
        self.instance = os.environ.get('INSTANCE_ID')
        self.endpoint = os.environ.get('IAM_ENDPOINT', 'https://iam.cloud.ibm.com')
        
        self.access_token = ''
        self.retry = False
        
        if not self.zhsm:
            print("$ZHSM environment variable is not set, defaulting to the original software AES")
            return
        
        print("zHSM=" + self.zhsm)
        if self.zhsm and (not self.apikey or not self.instance):
            print("$APIKEY or $INSTANCE_ID environment variable is not set - accessing an on-prem grep11 at " + self.zhsm)
            return
        
        if self.zhsm and self.apikey and self.instance:
            print("accessing an on-cloud HPCS (grep11) at " + self.zhsm)
            
        # print("APIKEY=" + self.apikey)
        print("INSTANCE_ID=" + self.instance)
        print("ENDPOINT=" + self.endpoint)


    class AuthPlugin(grpc.AuthMetadataPlugin):
        
        def __init__(self, instance_id, access_token):
            self._instance_id = instance_id
            self._access_token = access_token
    
        def __call__(self, context, callback):
            print('__call__ context=' + str(context))
            metadata = (('authorization', 'Bearer {}'.format(self._access_token)),('bluemix-instance', '{}'.format(self._instance_id)),)
            # print('metadata=' + str(metadata))
            callback(metadata, None)

    # get or renew an access token
    def get_access_token(self):
        print("accessing an HPCS instance on IBM Cloud")
        
        print("ZHSM=" + self.zhsm)
        # print("APIKEY=" + self.apikey)
        print("INSTANCE_ID=" + self.instance)
        print("ENDPOINT=" + self.endpoint)
    
        cmd = 'curl -sS -k -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" --data-urlencode "apikey=' + self.apikey + '" "' + self.endpoint + '/identity/token"'

        try:
            resp_str = check_output(cmd, shell=True).rstrip().decode('utf8')
        except Exception as e:
            print('an unexpected response from IAM_ENDPOINT=' + endpoint)
            print(e)
            import traceback
            traceback.print_exc()
            return None

        try:
            resp = json.loads(resp_str)
            # print('response=' + json.dumps(resp, indent=4))
            self.access_token = resp['access_token']
            print('access_token=' + 'xxxxxxxxxxxxxxxxxxxxxxxxx...')
            return self.access_token
        
        except Exception as e:
            print('an unexpected response from IAM_ENDPOINT=' + endpoint)
            print('response=' + str(resp_str))
            print(e)
            import traceback
            traceback.print_exc()
            return None

    def get_channel(self):
        if not self.zhsm:
            channel = None
        elif not self.apikey or not self.instance:
            print("$APIKEY or $INSTANCE_ID environment variable is not set - accessing an on-prem grep11 at " + self.zhsm)
            channel = grpc.insecure_channel(self.zhsm)
        else:
            print("accessing an HPCS instance on IBM Cloud")
            print("ZHSM=" + self.zhsm)
            # print("APIKEY=" + self.apikey)
            print("INSTANCE_ID=" + self.instance)
            print("ENDPOINT=" + self.endpoint)

            call_credentials = grpc.metadata_call_credentials(self.AuthPlugin(self.instance, self.access_token))
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
        channel = self.get_channel()
        # no ZHSM
        if not channel:
            return None
        
        grep11ServerStub = server_pb2_grpc.CryptoStub(channel)
        
        try:
            ep11key = self.ep11key(grep11ServerStub, key)
            print("pyep11.AES.encrypt: key=" + key.hex())

            cipherInitInfo = server_pb2.EncryptInitRequest(Mech=pkcs11_pb2.Mechanism(Mechanism=ep11.CKM_AES_CBC_PAD,
                                                                                     Parameter=iv),
                                                           Key = ep11key)
            cipherState = grep11ServerStub.EncryptInit(cipherInitInfo)
            
            cipherData = server_pb2.EncryptUpdateRequest(State=cipherState.State,
                                                         Plain=data)
            cipherState = grep11ServerStub.EncryptUpdate(cipherData)

            ciphertext = cipherState.Ciphered[:]
            cipherData.State = cipherState.State
            cipherData.Plain = b''
            cipherState = grep11ServerStub.EncryptFinal(cipherData)

            ciphertext = ciphertext + cipherState.Ciphered[:]
            # print("Original message  " + data.hex())
            # print("Encrypted message " + ciphertext.hex())

            self.retry = False
            
            return ciphertext

        except grpc.RpcError as rpc_error:
            print(f'encrypt_with_iv: RPC failed with code {rpc_error.code()}: {rpc_error}')
            print('grpc error code=' + str(rpc_error._state.code) + ' ' + str(type(rpc_error._state.code)))
            # retry once if the access token has expired
            if str(rpc_error._state.code) == 'StatusCode.UNAUTHENTICATED' and not self.retry:
                self.get_access_token()
                self.retry = True
                return self.encrypt_with_iv(key, iv, data)
            return None
    
        except Exception as e:
            exc_type, exc_obj, tb = sys.exc_info()
            lineno = tb.tb_lineno
            print('Unexpected error: ' + str(e) + ' ' + str(type(e)) + ' at ' + str(lineno))
            return None
    
    def decrypt_with_iv(self, key, iv, encrypted_data):
        channel = self.get_channel()
        # no ZHSM
        if not channel:
            return None
        
        grep11ServerStub = server_pb2_grpc.CryptoStub(channel)
        
        try:
            ep11key = self.ep11key(grep11ServerStub, key)
            print("pyep11.AES.decrypt: key=" + key.hex())

            cipherInitInfo = server_pb2.DecryptInitRequest(Mech=pkcs11_pb2.Mechanism(Mechanism=ep11.CKM_AES_CBC_PAD,
                                                                                     Parameter=iv),
                                                           Key = ep11key)
            cipherState = grep11ServerStub.DecryptInit(cipherInitInfo)
            
            cipherData = server_pb2.DecryptUpdateRequest(State=cipherState.State,
                                                         Ciphered=encrypted_data)
            cipherState = grep11ServerStub.DecryptUpdate(cipherData)

            plaintext = cipherState.Plain[:]
            cipherData.State = cipherState.State
            cipherData.Ciphered = b''
            cipherState = grep11ServerStub.DecryptFinal(cipherData)

            plaintext = plaintext + cipherState.Plain[:]
            # print("Decrypted message  " + plaintext.hex())
            # print("Encrypted message  " + encrypted_data.hex())

            self.retry = False
            
            return plaintext

        except grpc.RpcError as rpc_error:
            print(f'decrypt_with_iv: RPC failed with code {rpc_error.code()}: {rpc_error}')
            print('grpc error code=' + str(rpc_error._state.code) + ' ' + str(type(rpc_error._state.code)))
            # retry once if the access token has expired
            if str(rpc_error._state.code) == 'StatusCode.UNAUTHENTICATED' and not self.retry:
                self.get_access_token()
                self.retry = True
                return self.decrypt_with_iv(key, iv, encrypted_data)
            return None
    
        except Exception as e:
            exc_type, exc_obj, tb = sys.exc_info()
            lineno = tb.tb_lineno
            print('Unexpected error: ' + str(e) + ' ' + str(type(e)) + ' at ' + str(lineno))
            return None
    

