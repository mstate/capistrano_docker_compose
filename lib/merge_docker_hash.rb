class Hash
  def merge_docker_hash!(other_hash)
    # grab all keys not in self from other_hash and add them
    keys_unique_to_other_hash = (other_hash.keys || []) - self.keys
    keys_unique_to_other_hash.each do |other_hash_key|
      self[other_hash_key] = other_hash[other_hash_key]
    end

    # update keys from self with data from other_hash
    self.keys.each do |key|
      # no need to update if not included in other_hash
      next unless other_hash[key]

      case
        when self[key].kind_of?(Hash)
          # recursively merge if hash
          self[key].merge_docker_hash!(other_hash[key] || {})
        when self[key].kind_of?(Array)
          other_hash_value = (other_hash[key] || [])
          # append if both arrays
          if other_hash_value.kind_of?(Array)
            self[key] =( self[key] + other_hash_value).uniq
          else # otherwise, replace with value from other_hash
            self[key] = other_hash_value
          end
        else
          # otherwise replace
          self[key] = other_hash[key]
      end
    end
    return self
  end
end
