require 'sinatra'   # gem 'sinatra'
require 'line/bot'  # gem 'line-bot-api'

def generate_message(event)
  lineid, space_name = case event["source"]["type"]
    when "user"
      [ event["source"]["userId"], "ユーザー" ]
    when "group"
      [ event["source"]["groupId"], "グループ" ]
    when "room"
      [ event["source"]["roomId"], "ルーム" ]
    else
      [ event["source"]["userId"], "undefined" ]
    end

  message = {
    type: 'text',
    text: "こんにちは！\nあなたの#{space_name}は #{lineid} です！"
  }

  return message
end

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    halt 400, {'Content-Type' => 'text/plain'}, 'Bad Request'
  end

  events = client.parse_events_from(body)

  events.each do |event|
    case event
    when Line::Bot::Event::Follow
      lineid, space_name = case event["source"]["type"]
        when "user"
          [ event["source"]["userId"], "ユーザー" ]
        when "group"
          [ event["source"]["groupId"], "グループ" ]
        when "room"
          [ event["source"]["roomId"], "ルーム" ]
        else
          [ event["source"]["userId"], "undefined" ]
        end

      message = {
          type: 'text',
          text: "こんにちは！\nあなたの#{space_name}は #{lineid} です！"
        }

      res = client.reply_message(event['replyToken'], message)
      p res.value
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        message = generate_message(event)
      
        res = client.reply_message(event['replyToken'], message)
        p res.value
      end
    end
  end

  "OK"
end
