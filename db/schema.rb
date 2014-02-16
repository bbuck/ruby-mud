# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 1392540675) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "game_settings", force: true do |t|
    t.string   "content_title", default: ""
    t.text     "game_title",    default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "player_trackings", force: true do |t|
    t.string   "ip_address"
    t.integer  "connection_count"
    t.integer  "player_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "player_trackings", ["ip_address"], name: "index_player_trackings_on_ip_address", using: :btree

  create_table "players", force: true do |t|
    t.string   "username"
    t.string   "password_hash"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "room_id"
  end

  create_table "rooms", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "north"
    t.integer  "south"
    t.integer  "east"
    t.integer  "west"
    t.integer  "northwest"
    t.integer  "northeast"
    t.integer  "southwest"
    t.integer  "southeast"
    t.integer  "up"
    t.integer  "down"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "script"
    t.integer  "creator_id"
  end

end
