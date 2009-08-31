Last week I was privileged to present at our local Melbourne Ruby/Rails user group with fellow [CLEAR Interactive](http://www.clearinteractive.com.au) colleague Daniel Neighman. Daniel and I gave a talk about [RabbitMQ](http://www.rabbitmq.com), the exciting AMQP based messaging platform. 

We focused on discussing how [RabbitMQ](http://www.rabbitmq.com) and [AMQP](http://www.amqp.org) came into existence and its architecture. I also showed a few demo applications I'd prepared, one a Rails application that used RabbitMQ to resize and process images via Core Image in the background, the other, a RubyCocoa Desktop client that posted surf report measurements to a fanout exchange that drove a video news feed of surfer quotes.

The slides for the presentation are available at [slideshare](http://www.slideshare.net/crafterm/rabbitmq-messaging).

<div style="width:425px;text-align:left" id="__ss_1919416"><object style="margin:0px" width="425" height="355"><param name="movie" value="http://static.slidesharecdn.com/swf/ssplayer2.swf?doc=presentation-090828083401-phpapp01&stripped_title=rabbitmq-messaging" /><param name="allowFullScreen" value="true"/><param name="allowScriptAccess" value="always"/><embed src="http://static.slidesharecdn.com/swf/ssplayer2.swf?doc=presentation-090828083401-phpapp01&stripped_title=rabbitmq-messaging" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="425" height="355"></embed></object></div>

The example applications I demonstrated during the talk are available as a GitHub [project](http://github.com/crafterm/rabbit-mq-talk) as well.

Big thanks to Nick Marfleet for organising and [Square Circle Triangle](http://www.sct.com.au) for hosting the night, looking forward to next month already!