# Priority queue with array based heap.
#
# This is distributed freely in the sence of 
# GPL(GNU General Public License).
#
# K.Kodama 2005/09/01.  push_array, pop_array
# Rick Bradley 2003/02/02. patch for Ruby 1.6.5. Thank you!
# K.Kodama 2001/03/10. 1st version

class PQueue

	attr_accessor :qarray # format: [nil, e1, e2, ..., en]
	attr_reader :size # number of elements
	attr_reader :gt # compareProc
	
	def initialize(compareProc=lambda{|x,y| x>y})
		# By default, retrieves maximal elements first. 
		@qarray=[nil]; @size=0; @gt=compareProc; make_legal
	end
	private :initialize

	def upheap(k)
		k2=k.div(2); v=@qarray[k];
		while ((k2>0)and(@gt[v,@qarray[k2]]));
			@qarray[k]=@qarray[k2]; k=k2; k2=k2.div(2)
		end;
		@qarray[k]=v;
	end
	private :upheap

	def downheap(k)
		v=@qarray[k]; q2=@size.div(2)
		loop{
			if (k>q2); break; end;
			j=k+k; if ((j<@size)and(@gt[@qarray[j+1],@qarray[j]])); j=j+1; end;
			if @gt[v,@qarray[j]]; break; end;
			@qarray[k]=@qarray[j]; k=j;
		}
		@qarray[k]=v;
	end;
	private :downheap

	def make_legal
		for k in 2..@size do; upheap(k); end;
	end;

	def empty?
		return (0==@size)
	end

	def clear
		@qarray.replace([nil]); @size=0;
	end;

	def replace_array(arr=[])
		# Use push_array.
		@qarray.replace([nil]+arr); @size=arr.size; make_legal
	end;
	
	def clone
		q=new; q.qarray=@qarray.clone; q.size=@size; q.gt=@gt; return q;
	end;

	def push(v)
		@size=@size+1; @qarray[@size]=v; upheap(@size);
	end;

	def push_array(arr=[])
		@qarray[@size+1,arr.size]=arr; arr.size.times{@size+=1; upheap(@size)}
	end;

	def pop
		# return top element.  nil if queue is empty.
		if @size>0;
			res=@qarray[1]; @qarray[1]=@qarray[@size]; @size=@size-1;
			downheap(1);
			return res;
		else return nil
		end;
	end;

	def pop_array(n=@size)
		# return top n-element as an sorted array. (i.e. The obtaining array is decreasing order.)
		# See also to_a.
		a=[]
		n.times{a.push(pop)}
		return a
	end;
	
	def to_a
		# array sorted as increasing order.
		# See also pop_array.
		res=@qarray[1..@size];
		res.sort!{|x,y| if @gt[x,y]; 1;elsif @gt[y,x]; -1; else 0; end;}
		return res
	end

	def top
		# top element. not destructive.
		if @size>0; return @qarray[1]; else return nil; end;
	end;

	def replace_top_low(v)
		# replace top element if v<top element.
		if @size>0; @qarray[0]=v; downheap(0); return @qarray[0];
		else @qarray[1]=v; return nil;
		end;
	end;

	def replace_top(v)
		# replace top element
		if @size>0; res=@qarray[1]; @qarray[1]=v; downheap(1); return res;
		else @qarray[1]=v; return nil;
		end;
	end;

	def each_pop
		# iterate pop. destructive. Use as self.each_pop{|x| ... }. 
		while(@size>0); yield self.pop; end;
	end;

	def each_with_index
		# Not ordered. Use as self.each_with_index{|e,i| ... }. 
		for i in 1..@size do; yield @qarray[i],i; end;
	end

end # class pqueue

if $0 == __FILE__
	pq=PQueue.new(proc{|x,y| x>y})
	pq.push(2)
	pq.push(3)
	pq.push(4)
	pq.push(3)
	pq.push(2)
	pq.push(4)
	pq.push_array([3,5,4])
	print "size: "+pq.size.to_s+"\n"
	print "heap: "; pq.each_with_index{|x,y| print x.to_s+" "}; print "\n"
	print "to_a: "+pq.to_a.to_s+"\n"

	# a=pq.pop_array; p a.to_s
	print "pop : ";pq.each_pop{|x| print x.to_s+" "}; print "\n"
end;
