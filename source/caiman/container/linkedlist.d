/// Very simple but efficient linked list implementation
module caiman.container.linkedlist;

private struct Node(T)
{
public:
final:
    T data;
    Node!(T)* next;
}
public struct LinkedList(T)
{
private:
final:
@nogc:
    Node!(T)* node;

public:
    ptrdiff_t length;

    ref T opIndex(ptrdiff_t index)
    {
        Node!(T)* curr = node;
        while (index-- != 0)
            curr = curr.next;
        return curr.data;
    }

    T opIndexAssign(T val, size_t index) 
    {
        Node!(T)* curr = node;
        while (index-- != 0)
            curr = curr.next;
        return curr.data = val;
    }

    T opOpAssign(string op)(T val)
        if (op == "~" || op == "~=")
    {
        if (node == null)
        {
            auto next = Node!(T)(val, null);
            node = &next;
            length++;
            return val;
        }
        else 
        {
            Node!(T)* curr = node;
            while (curr.next != null)
                curr = curr.next;
            auto next = Node!(T)(val, null);
            curr.next = &next;
            length++;
            return val;
        }
    }

    void remove(ptrdiff_t index)
    {
        if (index == 0)
        {
            node = node.next;
        }
        else 
        {
            Node!(T)* curr = node;
            while (--index > 0)
                curr = curr.next;
            
            if (curr.next != null)
                curr.next = curr.next.next;
            length--;
        }
    }

    void clear()
    {
        node = null;
    }
}