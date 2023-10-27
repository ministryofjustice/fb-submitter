# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_05_11_104115) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0
    t.integer "attempts", default: 0
    t.text "handler"
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "email_payloads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "submission_id"
    t.string "attachments"
    t.datetime "succeeded_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "to"
  end

  create_table "submissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "service_slug"
    t.string "encrypted_user_id_and_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "completed_at"
    t.json "payload"
    t.text "access_token"
  end

end
