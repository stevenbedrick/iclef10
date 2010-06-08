# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_iclef10_session',
  :secret      => 'da751735e71e86593fb31a447a280a349dcbbefececa67f4c7a42787c738e94c3ccdd48783edaf5c099f4e8fd86f0a5617538457da6451db219d99c327c33fb0'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
