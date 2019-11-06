class Submission < ActiveRecord::Base
  include Concerns::HasStatusViaJob
end
