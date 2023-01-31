class InstallTwilioRails < ActiveRecord::Migration[7.0]
  def change
    create_table "messages", force: :cascade do |t|
      t.bigint "sms_conversation_id", null: false
      t.string "sid"
      t.text "body"
      t.string "status"
      t.string "direction"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["created_at"], name: "index_messages_on_created_at"
      t.index ["direction"], name: "index_messages_on_direction"
      t.index ["sms_conversation_id"], name: "index_messages_on_sms_conversation_id"
    end

    create_table "phone_callers", force: :cascade do |t|
      t.string "phone_number"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["phone_number"], name: "index_phone_callers_on_phone_number"
    end

    create_table "phone_calls", force: :cascade do |t|
      t.integer "phone_caller_id"
      t.string "sid"
      t.string "number"
      t.string "from_number"
      t.string "from_city"
      t.string "from_province"
      t.string "from_country"
      t.string "tree_name"
      t.string "direction"
      t.string "answered_by"
      t.boolean "unanswered", default: false
      t.string "call_status"
      t.integer "length_seconds"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["created_at"], name: "index_phone_calls_on_created_at"
      t.index ["direction"], name: "index_phone_calls_on_direction"
      t.index ["phone_caller_id"], name: "index_phone_calls_on_phone_caller_id"
      t.index ["product_id"], name: "index_phone_calls_on_product_id"
      t.index ["sid"], name: "index_calls_on_sid"
      t.index ["tree_name"], name: "index_phone_calls_on_tree_name"
    end

    create_table "recordings", force: :cascade do |t|
      t.bigint "phone_call_id", null: false
      t.string "recording_sid"
      t.string "duration"
      t.string "url"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["phone_call_id"], name: "index_recordings_on_call_id"
    end

    create_table "responses", force: :cascade do |t|
      t.bigint "phone_call_id"
      t.bigint "recording_id"
      t.string "prompt_handle"
      t.string "digits"
      t.text "transcription"
      t.boolean "transcribed", default: false
      t.boolean "timeout", default: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["created_at"], name: "index_responses_on_created_at"
      t.index ["digits"], name: "index_responses_on_digits"
      t.index ["moderation"], name: "index_responses_on_moderation"
      t.index ["phone_call_id", "prompt_handle"], name: "index_responses_on_phone_call_id_and_prompt_handle"
      t.index ["prompt_handle"], name: "index_responses_on_prompt_handle"
      t.index ["recording_id"], name: "index_responses_on_recording_id"
      t.index ["timeout"], name: "index_responses_on_timeout"
      t.index ["transcribed"], name: "index_responses_on_transcribed"
    end

    create_table "sms_conversations", force: :cascade do |t|
      t.string "number"
      t.string "from_number"
      t.string "from_city"
      t.string "from_province"
      t.string "from_country"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["created_at"], name: "index_sms_conversations_on_created_at"
      t.index ["from_number"], name: "index_sms_conversations_on_from_number"
      t.index ["number"], name: "index_sms_conversations_on_number"
    end
  end
end
