package tcp_test

import (
	"bytes"
	"testing"

	"github.com/khulnasoft/khulnasoft/pkg/tcp"
	"github.com/khulnasoft/khulnasoft/pkg/testies"
	"github.com/stretchr/testify/require"
)

func TestConnection(t *testing.T) {
	testies.SetupLogger()

	cmd := &tcp.TCPCommand{
		Command: byte('t'),
		Data:    []byte("69:420"),
	}

	b := []byte{}
	bin, err := cmd.MarshalBinary()
	require.NoError(t, err)

	for i := 0; i < 100; i++ {
		require.NoError(t, err)
		b = append(b, bin...)
	}

	r := bytes.NewReader(b)
	w := bytes.NewBuffer(nil)

	conn := tcp.Connection{
		Id:     0,
		Reader: tcp.NewFrameReader(r),
		Writer: tcp.NewFrameWriter(w),
	}

	for i := 0; i < 100; i++ {
		outCommand, err := conn.Next()
		require.NoError(t, err)
		require.Equal(t, outCommand, cmd)
	}

}
