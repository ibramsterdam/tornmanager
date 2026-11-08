class ApiKey::TmCompany < ApiKey
  encrypts :key, deterministic: true
end
