function testfunc()
	test = {hi = "hello world"}
	function test.testa(self)
		print("testa "..self.hi)
	end

	function test:testb()
		print("testb "..self.hi)
	end

	test.testc = function(self)
		print("testc "..self.hi)
	end
	return test
end

test = testfunc()

test:testa()
test:testb()
test:testc()