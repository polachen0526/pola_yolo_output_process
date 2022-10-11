import tensorflow as tf
import numpy as np

class sigmoid_inference(tf.keras.layers.Layer):
     #def __init__(self):
     #    super(sigmoid_inference,self).__init__()

     #def build(self,inputs):
     #    print("BUILD SIGMOID CLASS NOW~~~~~~~~~")

     def call(self,inputs):
        #print("CALL FUNC ABOUT SIGMOID!!!!!!!!!!!!!!!!!")
        eps = 1e-5
        value = inputs
        abs_value = tf.math.abs(value)
        tmp = tf.zeros_like(abs_value)
        cond_more_than_5                                            = tf.greater_equal(x=abs_value, y=5.0)
        cond_small_than_5_and_more_than_2point375                   = tf.equal(x=tf.less(abs_value,5.0), y=tf.greater_equal(x=abs_value, y=2.375))
        cond_small_than_2point375_and_more_than_1                   = tf.equal(x=tf.less(abs_value,2.375), y=tf.greater_equal(x=abs_value, y=1.0))
        cond_small_than_1_and_more_than_0                           = tf.equal(x=tf.less(abs_value,1.0), y=tf.greater_equal(x=abs_value, y=0.0))
        number_list_cond_more_than_5                                = tf.where(cond_more_than_5                             , 1.0, tmp)
        number_list_cond_small_than_5_and_more_than_2point375       = tf.where(cond_small_than_5_and_more_than_2point375    , abs_value * 0.03125 + 0.84375 , tmp)
        number_list_cond_small_than_2point375_and_more_than_1       = tf.where(cond_small_than_2point375_and_more_than_1    , abs_value * 0.125 + 0.625 , tmp)
        number_list_cond_small_than_1_and_more_than_0               = tf.where(cond_small_than_1_and_more_than_0            , abs_value * 0.25 + 0.5 , tmp)
        result = number_list_cond_more_than_5 +number_list_cond_small_than_5_and_more_than_2point375 + number_list_cond_small_than_2point375_and_more_than_1 + number_list_cond_small_than_1_and_more_than_0
        sign_result = tf.where(tf.less(x=value,y=0.0),(1.0-result+eps),result)
        #print(sign_result)
        return sign_result

def positive_cond(value , min_value , ones):
    #print(tf.logical_not(tf.reduce_all(tf.less(value , min_value))))
    return tf.logical_not(tf.reduce_all(tf.less(value , min_value)))

def positive_body(value , min_value ,ones):
    ones_5_542  =   tf.where(tf.greater_equal(x=value, y=5.542)             ,   ones*256.0     , tf.zeros_like(ones))
    ones_2_7726 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=2.7726) , y=tf.less(x=value , y=5.542 ) ),   ones*16.0      , tf.zeros_like(ones))
    ones_1_3863 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=1.3863) , y=tf.less(x=value , y=2.7726) ),   ones*4.0       , tf.zeros_like(ones))
    ones_0_6931 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.6931) , y=tf.less(x=value , y=1.3863) ),   ones*2.0       , tf.zeros_like(ones))
    ones_0_4055 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.4055) , y=tf.less(x=value , y=0.6931) ),   ones*(3/2    ) , tf.zeros_like(ones))
    ones_0_2231 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.2231) , y=tf.less(x=value , y=0.4055) ),   ones*(5/4    ) , tf.zeros_like(ones))
    ones_0_1178 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.1178) , y=tf.less(x=value , y=0.2231) ),   ones*(9/8    ) , tf.zeros_like(ones))
    ones_0_0606 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0606) , y=tf.less(x=value , y=0.1178) ),   ones*(17/16  ) , tf.zeros_like(ones))
    ones_0_0308 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0308) , y=tf.less(x=value , y=0.0606) ),   ones*(33/32  ) , tf.zeros_like(ones))
    ones_0_0155 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0155) , y=tf.less(x=value , y=0.0308) ),   ones*(65/64  ) , tf.zeros_like(ones))
    ones_0_0078 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0078) , y=tf.less(x=value , y=0.0155) ),   ones*(129/128) , tf.zeros_like(ones))
    ones_0      =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0)      , y=tf.less(x=value , y=0.0078) ),   ones         , tf.zeros_like(ones))
    ones_another=   tf.where(tf.less(x=value , y=0), 0.0 ,tf.zeros_like(ones))
    ones_result = ones_5_542 + ones_2_7726 + ones_1_3863 + ones_0_6931 + ones_0_4055 + ones_0_2231 + ones_0_1178 + ones_0_0606 + ones_0_0308 + ones_0_0155 + ones_0_0078 + ones_0 + ones_another

    cond_more_than_5_542  = tf.where(tf.greater_equal(x=value, y=5.542) , value-5.542 , tf.zeros_like(input=value))
    cond_more_than_2_7726 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=2.7726) , y=tf.less(x=value, y=5.542 )) , value-2.7726 , tf.zeros_like(input=value))
    cond_more_than_1_3863 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=1.3863) , y=tf.less(x=value, y=2.7726)) , value-1.3863 , tf.zeros_like(input=value))
    cond_more_than_0_6931 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.6931) , y=tf.less(x=value, y=1.3863)) , value-0.6931 , tf.zeros_like(input=value))
    cond_more_than_0_4055 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.4055) , y=tf.less(x=value, y=0.6931)) , value-0.4055 , tf.zeros_like(input=value))
    cond_more_than_0_2231 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.2231) , y=tf.less(x=value, y=0.4055)) , value-0.2231 , tf.zeros_like(input=value))
    cond_more_than_0_1178 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.1178) , y=tf.less(x=value, y=0.2231)) , value-0.1178 , tf.zeros_like(input=value))
    cond_more_than_0_0606 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0606) , y=tf.less(x=value, y=0.1178)) , value-0.0606 , tf.zeros_like(input=value))
    cond_more_than_0_0308 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0308) , y=tf.less(x=value, y=0.0606)) , value-0.0308 , tf.zeros_like(input=value))
    cond_more_than_0_0155 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0155) , y=tf.less(x=value, y=0.0308)) , value-0.0155 , tf.zeros_like(input=value))
    cond_more_than_0_0078 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0078) , y=tf.less(x=value, y=0.0155)) , value-0.0078 , tf.zeros_like(input=value))
    cond_more_than_0      = tf.where(tf.less(x=value, y=0.0078) , value , tf.zeros_like(input=value))
    cond_result = cond_more_than_5_542+cond_more_than_2_7726+cond_more_than_1_3863+cond_more_than_0_6931+cond_more_than_0_4055+cond_more_than_0_2231+cond_more_than_0_1178+cond_more_than_0_0606+cond_more_than_0_0308+cond_more_than_0_0155+cond_more_than_0_0078+cond_more_than_0

    return cond_result , min_value ,ones_result

def negative_cond(value , min_value , ones):
    return tf.logical_not(tf.reduce_all(tf.less(value , min_value)))

def negative_body(value , min_value ,ones):
    ones_5_542  =   tf.where(tf.greater_equal(x=value, y=5.542)             ,   ones/256.0     , tf.zeros_like(ones))
    ones_2_7726 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=2.7726) , y=tf.less(x=value , y=5.542 ) ),   ones/16.0        , tf.zeros_like(ones))
    ones_1_3863 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=1.3863) , y=tf.less(x=value , y=2.7726) ),   ones/4.0         , tf.zeros_like(ones))
    ones_0_6931 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.6931) , y=tf.less(x=value , y=1.3863) ),   ones/2.0         , tf.zeros_like(ones))
    ones_0_2877 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.2877) , y=tf.less(x=value , y=0.6931) ),   ones*(3/4    ) , tf.zeros_like(ones))
    ones_0_1335 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.1335) , y=tf.less(x=value , y=0.2877) ),   ones*(7/8    ) , tf.zeros_like(ones))
    ones_0_0645 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0645) , y=tf.less(x=value , y=0.1335) ),   ones*(15/16  ) , tf.zeros_like(ones))
    ones_0_0317 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0317) , y=tf.less(x=value , y=0.0645) ),   ones*(31/32  ) , tf.zeros_like(ones))
    ones_0_0157 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0157) , y=tf.less(x=value , y=0.0317) ),   ones*(63/64  ) , tf.zeros_like(ones))
    ones_0_0078 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0078) , y=tf.less(x=value , y=0.0157) ),   ones*(127/128) , tf.zeros_like(ones))
    ones_0_0039 =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0039) , y=tf.less(x=value , y=0.0078) ),   ones*(255/256) , tf.zeros_like(ones))
    ones_0      =   tf.where(tf.equal(x=tf.greater_equal(x=value, y=0)      , y=tf.less(x=value , y=0.0039) ),   ones           , tf.zeros_like(ones))
    ones_another=   tf.where(tf.less(x=value , y=0), 0.0 ,tf.zeros_like(ones))
    ones_result = ones_5_542 + ones_2_7726 + ones_1_3863 + ones_0_6931 + ones_0_2877 + ones_0_1335 + ones_0_0645 + ones_0_0317 + ones_0_0157 + ones_0_0078 + ones_0_0039 + ones_0 + ones_another

    cond_more_than_5_542  = tf.where(tf.greater_equal(x=value, y=5.542) , value-5.542 , tf.zeros_like(input=value))
    cond_more_than_2_7726 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=2.7726) , y=tf.less(x=value, y=5.542 )) , value-2.7726 , tf.zeros_like(input=value))
    cond_more_than_1_3863 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=1.3863) , y=tf.less(x=value, y=2.7726)) , value-1.3863 , tf.zeros_like(input=value))
    cond_more_than_0_6931 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.6931) , y=tf.less(x=value, y=1.3863)) , value-0.6931 , tf.zeros_like(input=value))
    cond_more_than_0_2877 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.2877) , y=tf.less(x=value, y=0.6931)) , value-0.2877 , tf.zeros_like(input=value))
    cond_more_than_0_1335 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.1335) , y=tf.less(x=value, y=0.2877)) , value-0.1335 , tf.zeros_like(input=value))
    cond_more_than_0_0645 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0645) , y=tf.less(x=value, y=0.1335)) , value-0.0645 , tf.zeros_like(input=value))
    cond_more_than_0_0317 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0317) , y=tf.less(x=value, y=0.0645)) , value-0.0317 , tf.zeros_like(input=value))
    cond_more_than_0_0157 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0157) , y=tf.less(x=value, y=0.0317)) , value-0.0157 , tf.zeros_like(input=value))
    cond_more_than_0_0078 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0078) , y=tf.less(x=value, y=0.0157)) , value-0.0078 , tf.zeros_like(input=value))
    cond_more_than_0_0039 = tf.where(tf.equal(x=tf.greater_equal(x=value, y=0.0039) , y=tf.less(x=value, y=0.0078)) , value-0.0039 , tf.zeros_like(input=value))
    cond_more_than_0      = tf.where(tf.less(x=value, y=0.0039) , value , tf.zeros_like(input=value))
    cond_result = cond_more_than_5_542+cond_more_than_2_7726+cond_more_than_1_3863+cond_more_than_0_6931+cond_more_than_0_2877+cond_more_than_0_1335+cond_more_than_0_0645+cond_more_than_0_0317+cond_more_than_0_0157+cond_more_than_0_0078+cond_more_than_0_0039+cond_more_than_0

    return cond_result , min_value ,ones_result

class exp_inference(tf.keras.layers.Layer):
    #def __init__(self):
    #    super(exp_inference,self).__init__()

    #def build(self,inputs):
    #    print("BUILD EXP CLASS NOW~~~~~~~~~")

    def call(self,inputs):
        #print("CALL FUNC ABOUNT EXPPPPPPPPPPPP")
        value = inputs
        positive_ones  = tf.ones_like(input=value)
        negative_ones  = tf.ones_like(input=value)
        positive_min_value_set = tf.constant(0.0078)
        negative_min_value_set = tf.constant(0.0039)
        positive_value = tf.where(tf.greater_equal(value , 0.0) , value , tf.ones_like(value)*-1.0)
        negative_value = tf.where(tf.less(value , 0.0) , tf.math.abs(value) , tf.ones_like(value)*-1.0)
        #print(type(tf.convert_to_tensor(positive_value)))
        #-----------------positive------------------
        positive_cond_value , positive_min_value , positive_ones_value = tf.while_loop(cond=positive_cond, body=positive_body, loop_vars=[positive_value , positive_min_value_set , positive_ones])
        negative_cond_value , negative_min_value , negative_ones_value = tf.while_loop(cond=negative_cond, body=negative_body, loop_vars=[negative_value , negative_min_value_set , negative_ones])

        return tf.add(positive_ones_value,negative_ones_value)

class sigmoid_cross_entropy_with_logits(tf.keras.layers.Layer):
    #def __init__(self):
    #    super(exp_inference,self).__init__()

    def call(self,logits,labels):
        #max(x,0)- x*z + log(1+exp(-abs(x)))
        return tf.math.maximum(logits,0)-logits*labels + tf.math.log(1+exp_inference()(-tf.math.abs(logits)))

if __name__ == '__main__':
    x = tf.constant([0.0 , 1.78 , 6 ,5.3 , -1 , -2, -0.523,-0.4235 , -10 ,10])
    x = exp(x)
    print(x)

