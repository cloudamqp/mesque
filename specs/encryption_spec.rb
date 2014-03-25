require 'minitest/autorun'
require_relative '../lib/mesque/encryption'
require 'securerandom'

describe Mesque::Encryption do
  before do
    key = SecureRandom.hex
    @enc = Mesque::Encryption.new key
  end

  describe 'when given a string' do
    it 'can encrypt and decrypt it' do
      data = '{"key":"value"}'
      encrypted, iv, tag = @enc.encrypt(data)
      decrypted_data = @enc.decrypt encrypted, iv, tag
      decrypted_data.must_equal data
    end
  end
end

