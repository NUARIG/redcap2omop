def power(base_num, pow_num)
result = 1
pow_num.time do |index|
    result = result * base_num
end
return result
end

puts pow(2, 3)