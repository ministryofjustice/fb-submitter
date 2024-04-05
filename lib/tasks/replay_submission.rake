namespace :replay_submission do
  desc "
  Replay a submission
  Usage
  rake replay_submission:process[<submission_id>]
  "
  task :process, [:submission_id] => :environment do |_t, args|
    if args[:submission_id].nil?
      puts 'Submission ID is required'
    else
      job = Delayed::Job.all.find { |j| j.handler.include?(args[:submission_id]) }
      if job.nil?
        puts "No job for submission ID #{args[:submission_id]}"
      else
        job.update!(run_at: 10.seconds.from_now)
        puts "Replayed job for job ID #{job.id} - submission ID #{args[:submission_id]}"
      end
    end
  end

  desc "
  Replay a submission with attachments
  Usage
  rake replay_submission:with_attachments[<submission_id>,<jwt_skew_override>]
  "
  task :with_attachments, [:submission_id, :jwt_skew_override] => :environment do |_t, args|
    submission = Submission.find(args[:submission_id])

    if args[:submission_id].nil? || args[:jwt_skew_override].nil?
      puts 'Submission ID is required' if args[:submission_id].nil?
      puts 'JWT skew override is required' if args[:jwt_skew_override].nil?
    else
      old_job = Delayed::Job.all.find { |j| j.handler.include?(args[:submission_id]) }

      if old_job.nil?
        puts "No job for submission ID #{args[:submission_id]}"
      else
        V2::ProcessSubmissionJob.perform_later(
          submission_id: submission.id,
          jwt_skew_override: args[:jwt_skew_override]
        )

        puts "Queued new job for submission ID #{args[:submission_id]}"

        old_job.destroy!
        puts "Destroyed previous delayed job #{old_job.id}"
      end
    end
  end
end
