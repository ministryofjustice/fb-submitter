class DbSweeper
  def call
    Submission.where('created_at < ?', age_threshold).destroy_all
  end

  private

  def age_threshold
    28.days.ago
  end
end
