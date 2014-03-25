module Mesque
  class Encryption
    def initialize(key = ENV['MESQUE_ENC_KEY'], cipher_method = 'aes-128-gcm')
      @key = [key].pack('H*')
      @cipher_method = cipher_method
    end

    def encrypt(data)
      cipher = OpenSSL::Cipher.new @cipher_method
      cipher.encrypt
      cipher.key = @key
      iv = cipher.random_iv
      cipher.auth_data = ''
      encrypted = cipher.update(data) + cipher.final
      tag = cipher.auth_tag
      [encrypted, iv, tag]
    end

    def decrypt(data, iv, tag)
      cipher = OpenSSL::Cipher.new @cipher_method
      cipher.decrypt
      cipher.key = @key
      cipher.iv = iv
      cipher.auth_tag = tag
      cipher.auth_data = ''

      cipher.update(data) + cipher.final
    end
  end
end

